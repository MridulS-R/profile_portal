# frozen_string_literal: true

class VisionIndexJob < ApplicationJob
  queue_as :default

  def perform
    run = VisionIndexRun.create!(started_at: Time.current)
    begin
      count = VisionIndexer.index_all
      run.update!(finished_at: Time.current, records_indexed: count, success: true)
      Rails.logger.info("[VisionIndexJob] Indexed #{count} records into pgvector")
    rescue => e
      run.update!(finished_at: Time.current, success: false, error: "#{e.class}: #{e.message}")
      Rails.logger.error("[VisionIndexJob] FAILED: #{e.class}: #{e.message}")
      raise
    end
  end
end
