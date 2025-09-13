require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Load cron schedule if present
  begin
    require "sidekiq/cron/job"
    schedule_path = Rails.root.join("config", "sidekiq.yml")
    if File.exist?(schedule_path)
      yaml = YAML.load_file(schedule_path)
      if yaml && yaml[":schedule"].is_a?(Hash)
        Sidekiq::Cron::Job.load_from_hash yaml[":schedule"]
      end
    end
  rescue LoadError
    Rails.logger.warn("sidekiq-cron not available; skipping schedule load")
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

