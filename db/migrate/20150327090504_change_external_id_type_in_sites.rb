class ChangeExternalIdTypeInSites < ActiveRecord::Migration
  def up
  	change_column :sites, :external_id, :string
  end

  def down
  end
end
