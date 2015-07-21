class RemoveFieldIdentifyFromCollection < ActiveRecord::Migration
  def up
    remove_column :collections, :field_identify
  end

  def down
    add_column :collections, :field_identify, :string
  end
end
