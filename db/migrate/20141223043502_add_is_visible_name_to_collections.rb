class AddIsVisibleNameToCollections < ActiveRecord::Migration
  def change
  	add_column :collections, :is_visible_name, :boolean, :default => true
  end
end
