require 'test_helper'

class GithubSyncWorkerTest < ActiveSupport::TestCase
  test 'performs sync for users with github_username' do
    u = users(:one)
    attrs = [{ repo_full_name: 'alicehub/synced', html_url: 'https://github.com/alicehub/synced', description: nil, language: 'Ruby', stars: 0, forks: 0, open_issues: 0, topics: [], homepage: nil, pushed_at: Time.now, fetched_at: Time.now }]

    fake = Object.new
    def fake.fetch_repos; []; end
    fake.define_singleton_method(:fetch_repos) { attrs }

    stub_singleton_method(GithubSyncService, :new, ->(username:) { fake }) do
      GithubSyncWorker.new.perform
    end

    assert Project.exists?(user: u, repo_full_name: 'alicehub/synced')
  end
end
