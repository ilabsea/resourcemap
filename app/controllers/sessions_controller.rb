class SessionsController < Devise::SessionsController
  include Concerns::MobileDeviceDetection

  before_filter :prepare_for_mobile, :only => [:new]
  def new
    ip = meet_alert_ip
    if ip.size >5
      @captcha = true
    else
      @captcha = false
    end
    # Check if user is login failed so it redirect from create action
    if params["user"]
      LoginFailedTracker.create!(:ip_address => request.remote_ip, :login_at => DateTime.now())
      ip.first.destroy if ip and ip.size > 5
    end
    super
  end

  def create
    if meet_alert_ip and meet_alert_ip.size > 5
      res = validate_captcha(RecaptchaSetting.private_key, params["recaptcha_challenge_field"], params["recaptcha_response_field"])
      if res.body.start_with? "true" 
        allow_to_login = true
      else
        redirect_to :action => :new
      end
    else
      allow_to_login = true
    end  
    if allow_to_login
      super
      unless current_user.nil?
        LoginFailedTracker.where("ip_address = ?",request.remote_ip).destroy_all
      end
    end
  end



  def meet_alert_ip
    number_of_failed = LoginFailedTracker.find_all_by_ip_address(request.remote_ip)
    return number_of_failed
  end
end
