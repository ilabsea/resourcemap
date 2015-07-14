class AddExternalIdToSites < ActiveRecord::Migration
  def change
    add_column :sites, :external_id, :integer
  end
end
