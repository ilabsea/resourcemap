class AddFieldParentToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :field_parent, :int
  end
end
