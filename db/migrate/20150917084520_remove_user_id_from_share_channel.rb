class RemoveUserIdFromShareChannel < ActiveRecord::Migration
  def up
    remove_column :share_channels, :user_id
  end

  def down
    add_column :share_channels, :user_id, :integer
  end
end
