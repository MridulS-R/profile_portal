require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test 'index selects by username param' do
    get demos_path(username: users(:one).github_username)
    assert_response :success
    assert_match /Demos/, response.body
  end

  test 'index selects by domain host when present' do
    host! domains(:one_domain).host
    get demos_path
    assert_response :success
  end

  test 'index falls back to site owner when no current or param' do
    begin
      old = ENV['SITE_OWNER_GITHUB']
      ENV['SITE_OWNER_GITHUB'] = users(:two).github_username
      get demos_path
      assert_response :success
    ensure
      ENV['SITE_OWNER_GITHUB'] = old
    end
  end
end
