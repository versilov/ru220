# encoding: utf-8

class ApplicationController < ActionController::Base

  before_filter :authorize
  protect_from_forgery
  
  rescue_from Exception, :with => :render_all_errors
  
  protected
    
    def authorize
      unless User.find_by_id(session[:user_id])
        redirect_to login_url, :alert => 'Пожалуйста, войдите в систему, используя логин и пароль.'
      end
    end

    
  def render_all_errors(exception)
    
    logger.error "\n\n\nException caught: #{exception}\n\n"
    logger.error exception.backtrace.join("\n")
    
    if Rails.env.production?
      ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
      render :template => 'errors/500', :status => 500, :layout => 'application'
    else
      raise exception
    end
  end
  
  def current_user
    if session[:user_id]
      User.find(session[:user_id])
    else
      nil
    end
  end
    
    
end
