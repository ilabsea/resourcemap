class RenameUsernameToUserEmailInActivities < ActiveRecord::Migration
  def up
  	rename_column :activities, :username, :user_email
  end

  def down
  end
end
