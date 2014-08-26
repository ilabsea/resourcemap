class Api::SessionsController < Devise::SessionsController
  before_filter :check_params, :login_attempt, only: :create
  skip_before_filter :require_no_authentication
  skip_before_filter :verify_authenticity_token
  
  ERRORS = {
    invalid: 'Error with your login or password.',
    invalid_token: 'Invalid authentication token.',
    unconfirmed: 'You have to confirm your account before continuing.'
  }

  def create
    render json: { success: true, auth_token: self.resource.authentication_token }, status: :created
  end

  def destroy
    user = User.find_by_authentication_token params[:auth_token]
    return invalid_attempt :invalid_token, :not_found unless user

    render json: { success: user.reset_authentication_token! }, status: :no_content
  end

  protected
    def login_attempt
      self.resource = User.find_for_database_authentication email: params[:user][:email]
      return invalid_attempt :invalid, :unauthorized unless resource
      return invalid_attempt :unconfirmed, :unauthorized unless resource.active_for_authentication?
      return invalid_attempt :invalid, :unauthorized unless resource.valid_password? params[:user][:password]
    end

    def check_params
      return invalid_attempt :invalid, :unauthorized unless params[:user]
    end

    def invalid_attempt reason, status
      warden.custom_failure!
      render json: { success: false, message: ERRORS[reason] }, status: status
    end
end
