class AddUserIdToShareChannel < ActiveRecord::Migration
  def change
    add_column :share_channels, :user_id, :integer
  end
end
