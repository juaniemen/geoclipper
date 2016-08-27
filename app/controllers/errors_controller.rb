class ErrorsController < ApplicationController
  def not_found
    render(:status => 404)
  end

  def internal_error
    render(:status => 500)
  end

  def permission_denied
    render(:status => 403)
  end

  def service_down
    render(:status =>503)
  end

end
