class AddIpTracking < ActiveRecord::Migration
  def change
    create_table :login_failed_trackers do |t|
      t.datetime :login_at
      t.string :ip_address
      t.timestamps
    end
  end
end