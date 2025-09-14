
class ApplicationController < ActionController::Base
  before_action :load_domain_user
  before_action :set_theme

  # Global, user-friendly error handling. In tests we let errors raise.
  unless Rails.env.test?
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
    rescue_from ActionController::ParameterMissing, with: :handle_bad_request
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from StandardError, with: :handle_application_error
  end

  private
  def require_admin!
    unless user_signed_in? && current_user.respond_to?(:admin) && current_user.admin?
      flash[:alert] = "You are not authorized to access that."
      redirect_to(root_path)
    end
  end
  # Prefer a deterministic landing page after login to avoid edge-cases
  # hitting the generic home route.
  def after_sign_in_path_for(resource)
    begin
      return public_profile_path(resource)
    rescue
      return root_path
    end
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
  def load_domain_user
    host = request.host
    cache_key = "domain_user:#{host}"
    @domain_user = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      Domain.includes(:user).find_by(host: host)&.user
    end
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

  def handle_bad_request(e)
    log_event(:warn, 'bad_request', e)
    respond_to do |format|
      format.html do
        flash[:alert] = "Invalid request. Please try again."
        redirect_back fallback_location: edit_profile_path
      end
      format.json { render json: { error: "bad_request" }, status: :bad_request }
    end
  end

  def handle_not_found(_e)
    log_event(:warn, 'not_found', _e)
    respond_to do |format|
      format.html do
        render 'errors/not_found', status: :not_found
      end
      format.json { render json: { error: "not_found" }, status: :not_found }
    end
  end

  def handle_application_error(e)
    log_event(:error, 'server_error', e)
    respond_to do |format|
      format.html do
        # Avoid redirect loops on pages like root; render a friendly error page instead.
        render 'errors/internal', status: :internal_server_error
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
