class AddUsernameToActivities < ActiveRecord::Migration
  def change
  	add_column :activities, :username, :string
  end
end
