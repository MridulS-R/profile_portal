require 'test_helper'

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: 'github',
      uid: '12345',
      info: {
        email: 'oauth@example.com',
        name: 'OAuth User',
        nickname: 'oauthnick',
        image: 'https://example.com/avatar.png',
        urls: { 'GitHub' => 'https://github.com/oauthnick' }
      }
    )
  end

  test 'github callback signs in and redirects' do
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    get '/users/auth/github/callback'
    assert_response :redirect
    follow_redirect!
    assert_response :redirect
  end
end
