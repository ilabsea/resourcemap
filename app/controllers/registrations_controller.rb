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
	params['user']['phone_number'].delete!('+')
    if params[:user][:current_password].blank? && params[:user][:password].empty? && params[:user][:password_confirmation].empty?
      current_user.update_attributes(params.slice(:phone_number))
      redirect_to collections_path, notice: "Account updated successfully"
    else
      super
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
