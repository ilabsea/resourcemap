require 'net/http'

namespace :activity do
  desc "Migrate the activity reference column to the log text"
  task :migrate => :environment do
    
    Activity.migrate_columns_to_log
    
  end
end