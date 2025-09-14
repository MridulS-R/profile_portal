
class ProfilesController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :connect_domain, :create_domain, :destroy_domain, :verify_domain]

  def home
    @user = @domain_user || site_owner || current_user || User.first
    if @user
      @projects = @user.projects.order(stars: :desc).limit(12)
      render :show and return
    end
  end

  def show
    @user = User.friendly.find(params[:slug])
    # Always show projects for the admin/site owner while keeping profile of @user
    owner = site_owner || @user

    # Conditional GET to enable 304 responses when unchanged
    latest_project_update = owner.projects.maximum(:updated_at)
    last_modified = [@user.updated_at, latest_project_update].compact.max
    etag = [@user.cache_key_with_version, owner.cache_key_with_version, latest_project_update&.to_i].compact

    if stale?(last_modified: last_modified, etag: etag, public: true)
      page = params[:page].to_i
      page = 1 if page <= 0
      per  = 24
      offset = (page - 1) * per
      @projects_owner = owner
      @projects = owner.projects.order(stars: :desc).limit(per).offset(offset)
      User.increment_counter(:views_count, @user.id) if @user.has_attribute?(:views_count)
    end
  end

  def edit
    @user = current_user
    @domains = @user.domains
  end

  def update
    @user = current_user
    attrs = user_params

    if attrs[:password].present? || attrs[:password_confirmation].present?
      if attrs[:current_password].blank?
        @user.errors.add(:current_password, "can't be blank")
        @domains = @user.domains
        render :edit, status: :unprocessable_content and return
      end
      if @user.update_with_password(attrs)
        bypass_sign_in(@user)
        redirect_to public_profile_path(@user), notice: "Profile and password updated"
      else
        @domains = @user.domains
        render :edit, status: :unprocessable_content
      end
    else
      # Handle resume attachment/removal
      if params[:remove_resume] == '1'
        @user.resume.purge_later if @user.resume.attached?
      end
      if attrs[:resume]
        @user.resume_scan_status = 'pending' if @user.respond_to?(:resume_scan_status)
        @user.resume.attach(attrs[:resume])
      end

      # Filter out attributes that don't exist on the model (e.g., when migrations haven't run)
      updatable = attrs.except(:current_password, :password, :password_confirmation, :resume)
      safe_attrs = updatable.to_h.symbolize_keys.select { |k, _| @user.has_attribute?(k) }

      if @user.update(safe_attrs)
        # enqueue background scan if a new resume was attached
        ResumeScanJob.perform_later(@user.id) if attrs[:resume]
        redirect_to public_profile_path(@user), notice: "Profile updated"
      else
        @domains = @user.domains
        render :edit, status: :unprocessable_content
      end
    end
  end

  def sync_github
    authenticate_user!
    if current_user.github_username.blank?
      redirect_to edit_profile_path, alert: "Set your GitHub username first." and return
    end

    GithubSyncUserJob.perform_later(current_user.id)
    redirect_to public_profile_path(current_user), notice: "GitHub sync queued. Your projects will update shortly."
  end

  def connect_domain; end

  def create_domain
    d = current_user.domains.build(host: params[:host])
    if d.save
      redirect_to edit_profile_path, notice: "Domain added. Point DNS A/CNAME to this app."
    else
      redirect_to edit_profile_path, alert: d.errors.full_messages.to_sentence
    end
  end

  def destroy_domain
    d = current_user.domains.find(params[:id])
    d.destroy
    redirect_to edit_profile_path, notice: "Domain removed"
  end

  def verify_domain
    d = current_user.domains.find(params[:id])
    unless d.respond_to?(:verification_token)
      redirect_to edit_profile_path, alert: "Domain verification not supported." and return
    end
    if params[:token] == d.verification_token
      d.update(verified_at: Time.current)
      redirect_to edit_profile_path, notice: "Domain verified"
    else
      redirect_to edit_profile_path, alert: "Invalid verification token"
    end
  end

  private
  def site_owner
    gh = ENV["SITE_OWNER_GITHUB"].presence
    gh && User.find_by(github_username: gh)
  end

  def user_params
    params.require(:user).permit(:name, :github_username, :bio, :website, :avatar_url, :banner_url,
                                 :twitter_url, :linkedin_url, :github_url, :youtube_url,
                                 :location, :skills, :theme, :education, :experience, :resume,
                                 :accent_color, :custom_css, :background_intensity, :allow_comments,
                                 :current_password, :password, :password_confirmation)
  end

  public
  # Serve resume with safe content-disposition based on type
  def resume
    @user = User.friendly.find(params[:slug])
    unless @user.resume.attached?
      head :not_found and return
    end

    blob = @user.resume.blob
    disp = %w[application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document].include?(blob.content_type) ? 'attachment' : 'inline'
    expires_in 1.hour, public: true
    redirect_to Rails.application.routes.url_helpers.rails_blob_path(@user.resume, disposition: disp, only_path: true)
  end
end
