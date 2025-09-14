class ResumeScanJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user&.resume&.attached?

    begin
      status = 'clean'
      infected = false
      user.resume.open do |file|
        begin
          safe = Clamby.safe?(file.path)
          infected = !safe
          status = safe ? 'clean' : 'infected'
        rescue => e
          Rails.logger.warn("[ResumeScanJob] scan skipped: #{e.class}: #{e.message}")
          status = 'skipped'
        end
      end

      user.update_columns(
        resume_scan_status: status,
        resume_virus_found: infected,
        updated_at: Time.current
      )

      if infected
        user.resume.purge
      end
    rescue => e
      Rails.logger.error("[ResumeScanJob] user=#{user_id} #{e.class}: #{e.message}")
    end
  end
end

