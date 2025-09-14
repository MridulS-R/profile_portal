
class ProjectsController < ApplicationController
  def index
    # Always show projects of the admin/site owner; fall back to first user
    user = site_owner || @domain_user || User.first

    if user
      @user = user
      @projects_owner = user
      @projects = @user.projects.order(stars: :desc)
      if params[:q].present?
        q = "%#{params[:q]}%"
        @projects = @projects.where("repo_full_name ILIKE ? OR description ILIKE ?", q, q)
      end
    else
      @projects = []
    end
  end

  private
  def site_owner
    gh = ENV["SITE_OWNER_GITHUB"].presence
    gh && User.find_by(github_username: gh)
  end
end
