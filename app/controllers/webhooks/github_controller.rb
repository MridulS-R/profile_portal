module Webhooks
  class GithubController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def receive
      signature = request.headers['X-Hub-Signature-256']
      secret = ENV['GITHUB_WEBHOOK_SECRET']
      if secret.present? && !valid_signature?(request.raw_post, signature, secret)
        head :unauthorized and return
      end

      event = request.headers['X-GitHub-Event']
      payload = JSON.parse(request.raw_post) rescue {}

      repo_full_name = payload.dig('repository', 'full_name')
      owner_login    = payload.dig('repository', 'owner', 'login') || payload.dig('sender', 'login')

      if repo_full_name && owner_login
        user = User.find_by(github_username: owner_login)
        if user
          begin
            service = GithubSyncService.new(username: user.github_username)
            attrs = service.fetch_repo(repo_full_name)
            proj = user.projects.find_or_initialize_by(repo_full_name: attrs[:repo_full_name])
            proj.assign_attributes(attrs)
            proj.save!
          rescue => e
            Rails.logger.error("[github_webhook] #{e.class}: #{e.message}")
          end
        end
      end

      head :ok
    end

    private
    def valid_signature?(payload_body, signature_header, secret)
      return false if signature_header.blank?
      expected = 'sha256=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload_body)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature_header)
    end
  end
end

