
class GithubSyncService
  def initialize(username:, token: ENV["GITHUB_TOKEN"])
    @client = Octokit::Client.new(access_token: token.presence)
    @username = username
  end

  def fetch_repos
    repos = @client.auto_paginate ? @client.repos(@username) : @client.repos(@username, per_page: 100)
    repos.map do |r|
      {
        repo_full_name: r.full_name,
        html_url:       r.html_url,
        description:    r.description,
        language:       r.language,
        stars:          r.stargazers_count,
        forks:          r.forks_count,
        open_issues:    r.open_issues_count,
        topics:         (r.respond_to?(:topics) ? r.topics : []),
        homepage:       r.homepage,
        pushed_at:      (r.pushed_at && Time.parse(r.pushed_at.to_s)),
        fetched_at:     Time.current
      }
    end
  end
end
