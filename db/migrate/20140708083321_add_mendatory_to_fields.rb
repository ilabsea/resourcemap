class AddMendatoryToFields < ActiveRecord::Migration
  def change
  	add_column :fields, :is_mendatory, :boolean, :default => false
  end
end
