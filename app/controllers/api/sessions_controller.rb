class Api::SessionsController < Devise::SessionsController
  before_filter :check_params, only: :create
  skip_before_filter :require_no_authentication

  def create
    user = User.find_for_database_authentication email: params[:user][:email]
    if user && user.valid_password?(params[:user][:password])
      render json: { success: true, auth_token: user.authentication_token }, status: :created
    else
      invalid_login_attempt
    end
  end

  def destroy
    user = User.find_by_authentication_token params[:auth_token]
    if user && user.reset_authentication_token!
      render :json => { }, :success => true, :status => 204
    else
      render :json => { :message => 'Invalid token.' }, :status => 404
    end
  end

  protected
    def invalid_login_attempt 
      warden.custom_failure!
      render json: { success: false, message: 'Error with your login or password' }, status: 401
    end

    def check_params
      return invalid_login_attempt unless params[:user]
    end
end
