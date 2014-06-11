class AddTimezoneToReminder < ActiveRecord::Migration
  def change
    add_column :reminders, :time_zone, :string
  end
end
