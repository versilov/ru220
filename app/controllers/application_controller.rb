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
    
  def clean_backtrace(exception)
    Rails.respond_to?(:backtrace_cleaner) ?
      Rails.backtrace_cleaner.send(:filter, exception.backtrace) : exception.backtrace
  end

  def render_all_errors(exception)
    logger.error "Exception caught: #{exception}"
    logger.error exception.backtrace.join("\n")
    
    ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    render :template => 'errors/500', :status => 500, :layout => 'application'
  end
    
    
end
