namespace :db do
  desc "Backup database by dumping sql and images"
  task backup_with_assets: :environment do
    Backup.sql_with_assets
  end
end
