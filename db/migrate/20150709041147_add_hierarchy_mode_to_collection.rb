class AddHierarchyModeToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :hierarchy_mode, :boolean
  end
end
