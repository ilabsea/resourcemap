class RegistrationsController < Devise::RegistrationsController
  include Concerns::MobileDeviceDetection
  include RecaptchaSetting

  helper_method :get_public_key
  helper_method :get_private_key

  before_filter :prepare_for_mobile

  def new
    super
  end

  def create
    validate = validate_captcha(RecaptchaSetting.private_key, params["recaptcha_challenge_field"], params["recaptcha_response_field"])
    if validate.body.start_with? "true"
      flash.delete :recaptcha_error
      super
    else
      flash.delete :recaptcha_error
      build_resource(sign_up_params)
      resource.valid?
      resource.errors.add(:base, "There was an error with the recaptcha code below. Please re-enter the code.")
      respond_with_navigational(resource) { render :new }    
    end
  end

  def update
    email_changed = current_user.email != params[:user][:email]
    password_changed = !params[:user][:password].empty?
    params['user']['phone_number'].delete!('+')
    successfully_updated = if email_changed or password_changed
                             current_user.update_with_password(params[:user])
                           else
                             params[:user].delete(:current_password)
                             current_user.update_without_password(params[:user])
                           end
    if successfully_updated
      # Sign in the user bypassing validation in case his password changed
      current_user.reset_authentication_token!
      sign_in current_user, :bypass => true
      redirect_to collections_path, notice: "Account updated successfully"
    else
      render "edit"
    end
  end

  def get_public_key
    RecaptchaSetting.public_key
  end

  def get_private_key
    RecaptchaSetting.private_key
  end

end
