module Concerns::MobileDeviceDetection
  extend ActiveSupport::Concern

  included do
    helper_method :mobile_device?
  end

  def mobile_device?  
    (from_mobile_browser? || session[:mobile_param] = 1) && params[:_desktop] != "true"
  end

  def from_mobile_browser?
    !!(request.user_agent =~ /Mobile|webOS/)
  end

  def prepare_for_mobile
    if params[:mobile]
      session[:mobile_param] = params[:mobile] 
      session[:desktop_param] = nil
    end

    if params[:_desktop]
      session[:desktop_param] = params[:_desktop]
      session[:mobile_param] = nil
    end
    request.format = :mobile if mobile_device?
  end
end