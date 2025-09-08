
class ProjectsController < ApplicationController
  def index
    user = @domain_user ||
      (params[:username].present? && User.find_by(github_username: params[:username])) ||
      current_user ||
      User.find_by(github_username: ENV["SITE_OWNER_GITHUB"])

    if user
      @user = user
      @projects = @user.projects.order(stars: :desc)
    else
      @projects = []
    end
  end
end
