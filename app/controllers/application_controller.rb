# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :authenticate

  # simple authentication to protect the live development site
  def authenticate
    #session[:user_id] = User.find_by_email('nico.ritsche@gmail.com').id
    return unless ENV['RAILS_ENV'] == 'production'
    authenticate_or_request_with_http_basic do |id, password|
      id == 'upload' && password == 'n0wupl0ad2oo9'
    end
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end
