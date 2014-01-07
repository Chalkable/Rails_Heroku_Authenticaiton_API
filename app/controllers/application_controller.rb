class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  def rescue_action_in_public(exception)
    @error = exception
    render "home/error"
  end
end
