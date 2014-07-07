class AddDefaultTimeZoneToUtcForUserAndReminder < ActiveRecord::Migration
  def up
    connection.execute("update users set time_zone='UTC'")
    connection.execute("update reminders set time_zone='UTC'")
  end

  def down

  end
end
