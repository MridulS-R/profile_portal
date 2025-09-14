class GithubSyncUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user&.github_username.present?

    service = GithubSyncService.new(username: user.github_username)
    repos = service.fetch_repos

    # Prepare bulk upsert payload
    now = Time.current
    rows = repos.map do |attrs|
      attrs.slice(:repo_full_name, :html_url, :description, :language, :stars, :forks, :open_issues, :topics, :homepage, :pushed_at, :fetched_at)
           .merge(user_id: user.id, updated_at: now, created_at: now)
    end

    # Upsert in chunks to avoid huge statements
    rows.each_slice(500) do |slice|
      Project.upsert_all(
        slice,
        unique_by: :index_projects_on_user_id_and_repo_full_name
      )
    end
  rescue Octokit::Unauthorized
    Rails.logger.warn("[GithubSyncUserJob] Unauthorized for user=#{user_id}")
  rescue Octokit::TooManyRequests
    Rails.logger.warn("[GithubSyncUserJob] Rate limited for user=#{user_id}")
  rescue Octokit::NotFound
    Rails.logger.warn("[GithubSyncUserJob] GitHub user not found for user=#{user_id}")
  rescue => e
    Rails.logger.error("[GithubSyncUserJob] user=#{user_id} #{e.class}: #{e.message}")
  end
end

