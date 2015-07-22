class DeleteFieldParentFromCollection < ActiveRecord::Migration
  def up
    remove_column :collections, :field_parent
  end

  def down
    add_column :collections, :field_parent, :int
  end
end
