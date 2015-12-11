class Api::SessionsController < Devise::SessionsController
  before_filter :check_guisso_basic_auth, only: :create
  skip_before_filter :require_no_authentication
  skip_before_filter :verify_authenticity_token
  
  ERRORS = {
    invalid: 'Error with your login or password.',
    invalid_token: 'Invalid authentication token.',
    unconfirmed: 'You have to confirm your account before continuing.'
  }

  def create
    if @current_user
      render json: { success: true, auth_token: @current_user.authentication_token }, status: :created
    else
      head :fobidden
    end
  end

  def destroy
    user = User.find_by_authentication_token params[:auth_token]
    sign_out current_user
    return invalid_attempt :invalid_token, :not_found unless user

    render json: { success: user.reset_authentication_token! }, status: :no_content
  end

  protected
    def check_guisso_basic_auth
      # return invalid_attempt :invalid, :unauthorized unless params[:user]
      authenticate_or_request_with_http_basic do |user, password|
        if AltoGuissoRails.valid_credentials?(user, password)
          @current_user = find_or_create_user(user)
          return
        end
      end
    end

    def invalid_attempt reason, status
      warden.custom_failure!
      render json: { success: false, message: ERRORS[reason] }, status: status
    end
end
