# encoding: utf-8

class ApplicationController < ActionController::Base
  before_filter :authorize
  protect_from_forgery
  
  
  
  protected
    
    def authorize
      unless User.find_by_id(session[:user_id])
        redirect_to login_url, :alert => 'Пожалуйста, войдите в систему, используя логин и пароль.'
      end
    end
    
  def render_optional_error_file(status_code)
    puts "OPTIONAL ERROR STATUS: #{status_code}"
    render :template => 'errors/500', :status => 500, :layout => 'application'
  end
    
    
end
