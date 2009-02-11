ActionController::Base.send :include, ResponseLogger if 'production' != RAILS_ENV
