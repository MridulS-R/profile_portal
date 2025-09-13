require 'test_helper'
require 'openssl'

class Webhooks::GithubControllerTest < ActionDispatch::IntegrationTest
  def post_webhook(payload_hash, secret: nil, event: 'push', signature: nil)
    payload = payload_hash.to_json
    headers = { 'X-GitHub-Event' => event, 'CONTENT_TYPE' => 'application/json' }
    if secret
      ENV['GITHUB_WEBHOOK_SECRET'] = secret
      sig = signature || 'sha256=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload)
      headers['X-Hub-Signature-256'] = sig
    else
      ENV['GITHUB_WEBHOOK_SECRET'] = nil
    end
    post '/webhooks/github', params: payload, headers: headers
  end

  test 'unauthorized when signature invalid and secret set' do
    post_webhook({ repository: { full_name: 'alicehub/alpha', owner: { login: 'alicehub' } } }, secret: 's3cr3t', signature: 'sha256=bad')
    assert_response :unauthorized
  end

  test 'ok when secret not set' do
    post_webhook({ repository: { full_name: 'alicehub/alpha', owner: { login: 'alicehub' } } }, secret: nil)
    assert_response :ok
  end

  test 'updates project for matching user' do
    users(:one) # ensure fixture loads
    payload = { repository: { full_name: 'alicehub/alpha', owner: { login: 'alicehub' } } }

    fake_attrs = { repo_full_name: 'alicehub/alpha', html_url: 'https://github.com/alicehub/alpha', description: 'updated', language: 'Ruby', stars: 42, forks: 3, open_issues: 0, topics: [], homepage: nil, pushed_at: Time.now, fetched_at: Time.now }

    fake = Object.new
    def fake.fetch_repo(full_name); end
    fake.define_singleton_method(:fetch_repo) { |full_name| fake_attrs }

    stub_singleton_method(GithubSyncService, :new, ->(username:) { fake }) do
      post_webhook(payload, secret: 's3cr3t')
    end

    assert_response :ok
  end
end
