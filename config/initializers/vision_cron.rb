# frozen_string_literal: true

begin
  require 'sidekiq/cron/job'
  # Use a standard cron expression by default (every 12 hours)
  cron = ENV.fetch('VISION_INDEX_CRON', '0 */12 * * *')
  Sidekiq::Cron::Job.create(
    name: 'Vision: Reindex content',
    cron: cron,
    class: 'VisionIndexJob'
  )
rescue LoadError
  Rails.logger.info('[vision_cron] sidekiq-cron not available; skipping schedule')
rescue => e
  Rails.logger.warn("[vision_cron] schedule failed: #{e.class}: #{e.message}")
end
