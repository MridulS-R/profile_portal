
require "active_support/core_ext/integer/time"
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  # Disable CSRF protection in test so we can post without tokens
  config.action_controller.allow_forgery_protection = false
  # Allow any host in test to support domain-based tests
  config.hosts.clear
end
