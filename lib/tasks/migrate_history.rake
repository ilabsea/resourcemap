task :environment

namespace :migrate do
  desc "Migrate current site history activity log to support site download history ..."
  task :history, [:ids,:include] => :environment do |t, args|
    total_migrated = 0
    list_collection_id = args[:ids].split(" ")
    total = Collection.all.size
    Collection.all.each_with_index do |collection, index|
      if(args[:include] == "true")
        if ((list_collection_id.include? collection.id.to_s))
          percentage  = 100 * (index+1) / total
          print "\rMigrating activity logs for download site history"
          Activity.migrate_site_activity(collection.id)
          total_migrated = total_migrated + 1
          print "\rMigrating activity logs for download site history #{index+1}/#{total}: %#{percentage}"
        end
      elsif(args[:include] == "false")
        unless ((list_collection_id.include? collection.id.to_s))
          percentage  = 100 * (index+1) / total
          print "\rMigrating activity logs for download site history"
          Activity.migrate_site_activity(collection.id)
          total_migrated = total_migrated + 1
          print "\rMigrating activity logs for download site history #{index+1}/#{total}: %#{percentage}"
        end
      end
    end
    print "\nTotal #{total_migrated} collections(s) migrated in #{total} of collections\n"
        
  end  
end
