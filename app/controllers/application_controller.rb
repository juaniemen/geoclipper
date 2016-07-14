class ApplicationController < ActionController::Base


    #Captura de errores y páginas no encontradas
    unless Rails.application.config.consider_all_requests_local
      rescue_from Exception, with: :render_500
      rescue_from ActionController::RoutingError, with: :render_404
      rescue_from ActionController::UnknownController, with: :render_404
      rescue_from AbstractController::ActionNotFound, with: :render_404
      rescue_from ActiveRecord::RecordNotFound, with: :render_404
    end

    def render_404(exception)
      render template: 'errors/error_404', layout: 'layouts/application', status: 404
    end

    def render_500(exception)
      @error = exception
      render template: 'errors/error_500', layout: 'layouts/application', status: 500
    end

    # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
