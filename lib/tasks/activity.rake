
require 'net/http'
namespace :activity do
  desc "Remove every activity for those user is nil"
  task remove_nil_user: :environment do
    Activity.remove_nil_user
  end
end

namespace :activity do
  desc "Migrate the activity reference column to the log text"
  task :migrate => :environment do
    Activity.migrate_columns_to_log
  end
end

