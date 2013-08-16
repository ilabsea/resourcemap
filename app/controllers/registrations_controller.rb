class RegistrationsController < Devise::RegistrationsController
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
    current_user.reset_authentication_token!
    if successfully_updated
      # Sign in the user bypassing validation in case his password changed
      sign_in current_user, :bypass => true
      redirect_to collections_path, notice: "Account updated successfully"
    else
      render "edit"
    end
  end

  private
  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end
end
