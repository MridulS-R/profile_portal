
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
    # Use Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Autoload and eager load lib for custom libraries (e.g., Vision)
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')
  end
end
