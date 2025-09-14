
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
    @projects = @user.projects.order(stars: :desc)
    @user.increment!(:views_count) if @user.has_attribute?(:views_count)
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

    begin
      service = GithubSyncService.new(username: current_user.github_username)
      repos = service.fetch_repos
      repos.each do |attrs|
        proj = current_user.projects.find_or_initialize_by(repo_full_name: attrs[:repo_full_name])
        proj.assign_attributes(attrs)
        proj.save!
      end
      redirect_to public_profile_path(current_user), notice: "GitHub projects synced"
    rescue Octokit::Unauthorized
      redirect_to edit_profile_path, alert: "GitHub auth failed. Check GITHUB_TOKEN or try again later." 
    rescue Octokit::TooManyRequests
      redirect_to edit_profile_path, alert: "GitHub rate limit exceeded. Set GITHUB_TOKEN to increase limits." 
    rescue Octokit::NotFound
      redirect_to edit_profile_path, alert: "GitHub user not found. Verify your GitHub username." 
    rescue ActiveRecord::RecordNotUnique
      redirect_to edit_profile_path, alert: "Duplicate repo detected. Contact support to resolve project index uniqueness." 
    rescue => e
      Rails.logger.error("[sync_github] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      redirect_to edit_profile_path, alert: "GitHub sync failed: #{e.class}. See logs."
    end
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
    send_data @user.resume.download,
              filename: blob.filename.to_s,
              type: blob.content_type,
              disposition: disp
  end
end
