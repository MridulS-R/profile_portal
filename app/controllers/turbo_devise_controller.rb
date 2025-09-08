
class TurboDeviseController < ApplicationController
  class Responder < ActionController::Responder
    def to_turbo_stream
      controller.render(options.merge(formats: :html)) unless has_errors? && default_action
    rescue ActionView::MissingTemplate => e
      if get? || has_errors?
        raise e
      else
        redirect_to navigation_location
      end
    end
  end
  self.responder = Responder
  respond_to :html, :turbo_stream
end
