
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
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.lograge.enabled = true
  # Disable CSS compression via SassC; modern CSS (e.g., @supports selector(:has()))
  # is not understood by SassC's compressor and raises during precompile.
  config.assets.css_compressor = nil
  # If your app is accessed via multiple hostnames or proxies, origin checks can
  # cause CSRF 422s when the Origin header differs. Disable with caution.
  if ENV["DISABLE_FORGERY_ORIGIN_CHECK"] == "true"
    config.action_controller.forgery_protection_origin_check = false
  end
end
