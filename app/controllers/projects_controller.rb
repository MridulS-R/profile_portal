
class ProjectsController < ApplicationController
  def index
    # Always show projects of the admin/site owner; fall back to first user
    user = site_owner || @domain_user || User.first

    if user
      @user = user
      @projects_owner = user
      @projects = @user.projects.order(stars: :desc)
      # Filters
      if params[:lang].present? && params[:lang] != 'all'
        @projects = @projects.where(language: params[:lang])
      end
      if params[:q].present?
        q = "%#{params[:q]}%"
        @projects = @projects.where("repo_full_name ILIKE ? OR description ILIKE ?", q, q)
      end
      if params[:topic].present?
        @projects = @projects.where("topics ILIKE ?", "%#{params[:topic]}%")
      end
      # Pagination
      page = params[:page].to_i
      page = 1 if page <= 0
      per  = 24
      offset = (page - 1) * per
      @projects = @projects.limit(per).offset(offset)

      # Build filter options
      @languages = @user.projects.where.not(language: [nil, ""]).distinct.pluck(:language).sort
      begin
        all_topics = @user.projects.pluck(:topics).compact
        parsed = all_topics.map do |t|
          if t.is_a?(String)
            begin
              JSON.parse(t)
            rescue StandardError
              Array.wrap(t)
            end
          else
            t
          end
        end
        @all_topics = parsed.flatten.compact.uniq.sort
      rescue
        @all_topics = []
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
