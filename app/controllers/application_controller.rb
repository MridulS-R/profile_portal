
class ApplicationController < ActionController::Base
  before_action :load_domain_user
  before_action :set_theme

  private
  def load_domain_user
    host = request.host
    @domain_user = Domain.includes(:user).find_by(host: host)&.user
  end

  def set_theme
    @theme = current_user&.theme || "light"
  end
end
