task :environment

namespace :history do
  desc "Migrate current site history activity log to support site download history ..."
  task :site => :environment do
    total = Collection.all.size
    Collection.all.each_with_index do |collection, index|
      percentage  = 100 * (index+1) / total
      print "\rMigrating activity logs for download site history"
      Activity.migrate_site_activity(collection.id)
      print "\rMigrating activity logs for download site history #{index+1}/#{total}: %#{percentage}"
    end
    print "\nDone Total #{total} collections(s) migrated \n"
    
  end
  
  
  
  
end