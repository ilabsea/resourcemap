class ThresholdMailer < ActionMailer::Base
  default from: "noreply@resourcemap.instedd.org"

  def notify_email(message, user_ids)
    users = User.find(user_ids)
    emails = users.map {|user| user.email}
    
    mail(:to => emails, :subject => "[ResourceMap] Alert Notification") do |format|
      format.text {render :text => message}
    end
  end
end
