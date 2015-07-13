namespace :user do
  desc "Export user as csv"
  task :export, [:path] => :environment do |t, args|
    puts "exporting user to #{args[:path]}"
    if args[:path].present?
      CSV.open(args[:path], "wb") do |csv|
        csv << ["email", "password", "pepper"]
        User.find_each do |user|
          csv << [user.email, user.encrypted_password, User.pepper]
        end
      end
    end
  end
end