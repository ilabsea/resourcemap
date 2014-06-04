class RemoveNuntiumChannelNameFromChannel < ActiveRecord::Migration
  def up
    remove_column :channels, :nuntium_channel_name
  end

  def down
    add_column :channels, :nuntium_channel_name, :string
  end
end
