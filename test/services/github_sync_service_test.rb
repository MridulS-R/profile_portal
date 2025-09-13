require 'test_helper'

class GithubSyncServiceTest < ActiveSupport::TestCase
  RepoStruct = Struct.new(:full_name, :html_url, :description, :language, :stargazers_count, :forks_count, :open_issues_count, :topics, :homepage, :pushed_at)

  test 'fetch_repos maps octokit response' do
    fake_repos = [
      RepoStruct.new('alicehub/alpha', 'https://github.com/alicehub/alpha', 'Alpha', 'Ruby', 7, 1, 0, %w[rails], nil, Time.now)
    ]

    fake_client = Object.new
    def fake_client.auto_paginate=(v); end
    fake_client.define_singleton_method(:repos) { |username| fake_repos }

    stub_singleton_method(Octokit::Client, :new, ->(access_token:) { fake_client }) do
      svc = GithubSyncService.new(username: 'alicehub', token: 'x')
      list = svc.fetch_repos
      assert_equal 1, list.size
      attrs = list.first
      assert_equal 'alicehub/alpha', attrs[:repo_full_name]
      assert_equal 'Ruby', attrs[:language]
      assert attrs[:fetched_at]
    end
  end
end
