
class ProjectsController < ApplicationController
  def index
    user = @domain_user ||
      (params[:username].present? && User.find_by(github_username: params[:username])) ||
      current_user ||
      User.find_by(github_username: ENV["SITE_OWNER_GITHUB"])

    if user
      @user = user
      @projects = @user.projects.order(stars: :desc)
      if params[:q].present?
        q = "%#{params[:q]}%"
        @projects = @projects.where("repo_full_name ILIKE ? OR description ILIKE ?", q, q)
      end
    else
      @projects = []
    end
  end
end
