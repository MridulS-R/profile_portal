class GithubSyncWorker
  include Sidekiq::Job

  def perform
    User.where.not(github_username: [nil, ""]).find_each do |user|
      begin
        service = GithubSyncService.new(username: user.github_username)
        repos = service.fetch_repos
        repos.each do |attrs|
          proj = user.projects.find_or_initialize_by(repo_full_name: attrs[:repo_full_name])
          proj.assign_attributes(attrs)
          proj.save!
        end
      rescue => e
        Rails.logger.error("[GithubSyncWorker] user=#{user.id} #{e.class}: #{e.message}")
      end
    end
  end
end

