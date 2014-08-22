class AddIsEnableFieldLogicToFields < ActiveRecord::Migration
  def change
  	add_column :fields, :is_enable_field_logic, :boolean, :default => false
  end
end
