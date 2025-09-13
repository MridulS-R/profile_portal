
# frozen_string_literal: true
Devise.setup do |config|
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "no-reply@example.com")
  require "devise/orm/active_record"
  if ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
    config.omniauth :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"], scope: "read:user"
  end
  if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    config.omniauth :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], scope: "userinfo.email,userinfo.profile"
  end
  config.navigational_formats = ["*/*", :html, :turbo_stream]
  config.parent_controller = "TurboDeviseController"
  config.secret_key = ENV["DEVISE_SECRET_KEY"] if ENV["DEVISE_SECRET_KEY"].present?
end
