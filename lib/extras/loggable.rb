module Loggable
  def log_message_with_percentage msg, uploaded, total
    amount = uploaded*100/total
    msg = "#{sprintf('%.2f', amount)}% - #{msg}"
    log_message msg
  end

  def log_message msg
    raise 'Your need to define LOG_NAME in your class' unless defined? self.class::LOG_NAME
    Log.info(self.class::LOG_NAME, msg)
    print "\r#{msg}"
  end

end
