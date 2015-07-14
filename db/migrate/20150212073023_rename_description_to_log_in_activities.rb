class RenameDescriptionToLogInActivities < ActiveRecord::Migration
  def up
  	rename_column :activities, :description, :log
  end

  def down
  end
end
