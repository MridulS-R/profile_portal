
class ApplicationController < ActionController::Base
  before_action :load_domain_user

  private
  def load_domain_user
    host = request.host
    @domain_user = Domain.includes(:user).find_by(host: host)&.user
  end
end
