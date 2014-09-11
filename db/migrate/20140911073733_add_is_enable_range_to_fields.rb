class AddIsEnableRangeToFields < ActiveRecord::Migration
  def change
  	add_column :fields, :is_enable_range, :boolean, :default => false
  end
end
