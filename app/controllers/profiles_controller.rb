
class ProfilesController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :connect_domain, :create_domain, :destroy_domain]

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
  end

  def edit
    @user = current_user
    @domains = @user.domains
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to public_profile_path(@user), notice: "Profile updated"
    else
      render :edit, status: :unprocessable_entity
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

  private
  def site_owner
    gh = ENV["SITE_OWNER_GITHUB"].presence
    gh && User.find_by(github_username: gh)
  end

  def user_params
    params.require(:user).permit(:name, :github_username, :bio, :website, :avatar_url, :banner_url,
                                 :twitter_url, :linkedin_url, :github_url, :youtube_url)
  end
end
