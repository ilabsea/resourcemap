class AddChannelIdToShareNationalChannels < ActiveRecord::Migration
  def change
    add_column :share_national_channels, :channel_id, :integer, belongs_to: :channels
  end
end
