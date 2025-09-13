require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test 'home renders for domain user first' do
    host! domains(:one_domain).host
    get root_path
    assert_response :success
  end

  test 'home falls back to site owner' do
    begin
      old = ENV['SITE_OWNER_GITHUB']
      ENV['SITE_OWNER_GITHUB'] = users(:two).github_username
      get root_path
      assert_response :success
    ensure
      ENV['SITE_OWNER_GITHUB'] = old
    end
  end

  test 'show by slug' do
    get public_profile_path(users(:one))
    assert_response :success
  end

  test 'requires auth for edit' do
    get edit_profile_path
    assert_response :redirect
  end

  test 'edit loads for signed in user' do
    sign_in users(:one)
    get edit_profile_path
    assert_response :success
  end

  test 'update profile without password succeeds' do
    sign_in users(:one)
    patch profile_path, params: { user: { name: 'New Name' } }
    assert_redirected_to public_profile_path(users(:one))
  end

  test 'update password requires current_password' do
    sign_in users(:one)
    patch profile_path, params: { user: { password: 'newpass123', password_confirmation: 'newpass123' } }
    assert_response :unprocessable_entity
  end

  test 'sync_github requires github_username' do
    user = users(:one)
    user.update!(github_username: nil)
    sign_in user
    post sync_github_path
    assert_redirected_to edit_profile_path
    follow_redirect!
    assert_match(/Set your GitHub username first/, response.body)
  end

  test 'sync_github success creates/updates projects' do
    sign_in users(:one)

    fake_attrs = [
      { repo_full_name: 'alicehub/newrepo', html_url: 'https://github.com/alicehub/newrepo', description: 'desc', language: 'Ruby', stars: 1, forks: 0, open_issues: 0, topics: [], homepage: nil, pushed_at: Time.now, fetched_at: Time.now }
    ]

    fake = Struct.new(:username) { def fetch_repos; end }.new('alicehub')
    fake.define_singleton_method(:fetch_repos) { fake_attrs }
    stub_singleton_method(GithubSyncService, :new, ->(username:) { fake }) do
      post sync_github_path
    end

    assert_redirected_to public_profile_path(users(:one))
  end

  test 'create and destroy domain' do
    sign_in users(:one)
    post domains_path, params: { host: 'new.example.com' }
    assert_redirected_to edit_profile_path

    d = Domain.find_by(host: 'new.example.com')
    assert d

    delete domain_path(d)
    assert_redirected_to edit_profile_path
    assert_nil Domain.find_by(id: d.id)
  end
end
