class AddEnaleSkipLogicToFields < ActiveRecord::Migration
  def change
  	add_column :fields, :enable_skip_logic, :boolean, :default => false
  end
end
