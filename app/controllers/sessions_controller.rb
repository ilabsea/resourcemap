class SessionsController < Devise::SessionsController
  include Concerns::MobileDeviceDetection

  before_filter :prepare_for_mobile, :only => [:new]
end
