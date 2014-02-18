module Concerns::MobileDeviceDetection
  extend ActiveSupport::Concern

  included do
    helper_method :mobile_device?
  end

  def mobile_device?
    from_mobile_browser? || session[:mobile_param] == "1"
  end

  def from_mobile_browser?
    !!(request.user_agent =~ /Mobile|webOS/)
  end

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end
end