class AddCollectionNameToActivities < ActiveRecord::Migration
  def change
  	add_column :activities, :collection_name, :string
  end
end
