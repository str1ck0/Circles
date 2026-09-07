class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :first_name, :last_name, :email, :password, :password_confirmation, :photo])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :first_name, :last_name, :bio, :email, :password, :password_confirmation, :photo])
  end

  private

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "You don't have access to that." }
      format.json { render json: { error: "You don't have access to that." }, status: :forbidden }
      format.any  { head :forbidden }
    end
  end
end
