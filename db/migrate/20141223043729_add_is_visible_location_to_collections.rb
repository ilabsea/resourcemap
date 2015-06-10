class AddIsVisibleLocationToCollections < ActiveRecord::Migration
  def change
  	add_column :collections, :is_visible_location, :boolean, :default => true
  end
end
