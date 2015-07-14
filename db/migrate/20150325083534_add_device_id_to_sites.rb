class AddDeviceIdToSites < ActiveRecord::Migration
  def change
    add_column :sites, :device_id, :string
  end
end
