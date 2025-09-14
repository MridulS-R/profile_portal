
class ApplicationController < ActionController::Base
  before_action :load_domain_user
  before_action :set_theme

  # Global, user-friendly error handling. In tests we let errors raise.
  unless Rails.env.test?
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from StandardError, with: :handle_application_error
  end

  private
  def load_domain_user
    host = request.host
    @domain_user = Domain.includes(:user).find_by(host: host)&.user
  end

  def set_theme
    @theme = current_user&.theme || "light"
  end

  def handle_csrf_error(_e)
    log_event(:warn, 'csrf_error', _e)
    reset_session
    respond_to do |format|
      format.html do
        flash[:alert] = "Your session has expired or is invalid. Please try again."
        redirect_back fallback_location: root_path
      end
      format.json { render json: { error: "invalid_authenticity_token" }, status: :unprocessable_content }
    end
  end

  def handle_not_found(_e)
    log_event(:warn, 'not_found', _e)
    respond_to do |format|
      format.html do
        flash[:alert] = "We couldn't find what you were looking for."
        redirect_back fallback_location: root_path
      end
      format.json { render json: { error: "not_found" }, status: :not_found }
    end
  end

  def handle_application_error(e)
    log_event(:error, 'server_error', e)
    respond_to do |format|
      format.html do
        flash[:alert] = "Something went wrong. Please try again."
        redirect_back fallback_location: root_path
      end
      format.json { render json: { error: "server_error" }, status: :internal_server_error }
    end
  end

  def log_event(level, kind, exception = nil)
    begin
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      raw_params = request.respond_to?(:filtered_parameters) ? request.filtered_parameters : request.parameters
      params_filtered = filter.filter(raw_params || {}).dup
      params_filtered.delete('controller')
      params_filtered.delete('action')
      msg = {
        kind: kind,
        error: exception && "#{exception.class}: #{exception.message}",
        method: request.request_method,
        path: request.fullpath,
        status: (response&.status rescue nil),
        user_id: (current_user&.id rescue nil),
        request_id: (request.request_id rescue nil),
        ip: (request.remote_ip rescue nil),
        referer: (request.referer rescue nil),
        user_agent: (request.user_agent rescue nil),
        params: params_filtered
      }
      Rails.logger.public_send(level, msg.to_json)
    rescue => log_e
      Rails.logger.public_send(level, "[#{kind}] #{exception&.class}: #{exception&.message}") rescue nil
    end
  end
end
