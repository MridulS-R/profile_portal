
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    auth = request.env["omniauth.auth"]
    @user = User.find_by(provider: "github", uid: auth.uid) ||
            (auth.info.email && User.find_by(email: auth.info.email)) ||
            User.new

    @user.provider = "github"
    @user.uid      = auth.uid
    @user.email    ||= auth.info.email.presence || "gh_#{auth.uid}@example.invalid"
    @user.password ||= Devise.friendly_token[0,20]
    @user.name     ||= auth.info.name.presence || auth.info.nickname
    @user.github_username = auth.info.nickname if auth.info.nickname.present?
    @user.avatar_url = auth.info.image if auth.info.image.present?
    @user.github_url = auth.info.urls.try(:[], "GitHub")
    @user.save!

    sign_in_and_redirect @user, event: :authentication
    set_flash_message!(:notice, :success, kind: "GitHub")
  rescue => e
    Rails.logger.error("[omniauth] #{e.class}: #{e.message}")
    redirect_to new_user_session_path, alert: "GitHub login failed."
  end

  def google_oauth2
    auth = request.env["omniauth.auth"]
    @user = User.find_by(provider: "google_oauth2", uid: auth.uid) ||
            (auth.info.email && User.find_by(email: auth.info.email)) ||
            User.new

    @user.provider = "google_oauth2"
    @user.uid      = auth.uid
    @user.email    ||= auth.info.email.presence || "google_#{auth.uid}@example.invalid"
    @user.password ||= Devise.friendly_token[0,20]
    @user.name     ||= auth.info.name
    @user.avatar_url = auth.info.image if auth.info.image.present?
    @user.save!

    sign_in_and_redirect @user, event: :authentication
    set_flash_message!(:notice, :success, kind: "Google")
  rescue => e
    Rails.logger.error("[omniauth] #{e.class}: #{e.message}")
    redirect_to new_user_session_path, alert: "Google login failed."
  end

  def failure
    redirect_to root_path, alert: "OAuth failed."
  end
end
