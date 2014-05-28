class RegistrationsController < Devise::RegistrationsController
  include Concerns::MobileDeviceDetection

  before_filter :prepare_for_mobile

  def new
    super
  end

  def create
    params['user']['phone_number'].delete!('+')
    super
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
end
