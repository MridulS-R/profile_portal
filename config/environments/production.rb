
require "active_support/core_ext/integer/time"
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.active_storage.service = :local
  config.log_level = :info
  config.log_tags = [:request_id]
  config.force_ssl = true
  config.hosts.clear
  config.action_mailer.perform_caching = false
  # Configure default URL options for Devise mailers (password reset links)
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "example.com"),
    protocol: ENV.fetch("APP_PROTOCOL", "https")
  }
  # Optional SMTP settings; set ENV vars to enable real delivery
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              ENV["SMTP_ADDRESS"],
      port:                 ENV.fetch("SMTP_PORT", 587).to_i,
      domain:               ENV["SMTP_DOMAIN"],
      user_name:            ENV["SMTP_USERNAME"],
      password:             ENV["SMTP_PASSWORD"],
      authentication:       ENV.fetch("SMTP_AUTH", "plain"),
      enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true"
    }
  end
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.lograge.enabled = true
end
