Ru220::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false
  
  config.log_level = :debug

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  config.extrapost_site = 'http://localhost:4000/'
  
  config.middleware.use ExceptionNotifier,
    :email_prefix => '[RU220 Exception] ',
    :sender_address => %{"Exception Notifier" <notifier@220ru.ru>},
    :exception_recipients => %w{stas.versilov@gmail.com}
  
  # Email sending config
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
  :address              => "smtp.extrastore.ru",
  :port                 => 2525,
  :user_name            => 'smtp@extrastore.ru',
  :password             => 'rubysmtp',
  :authentication       => :login
  }
end


  

