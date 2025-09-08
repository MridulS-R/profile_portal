
# frozen_string_literal: true
require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module ProfilePortal
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = "UTC"
    config.generators.system_tests = nil
    config.active_record.schema_format = :sql
    config.hosts.clear
    config.force_ssl = false
    config.lograge.enabled = true
  end
end
