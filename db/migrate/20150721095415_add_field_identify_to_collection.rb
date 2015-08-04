class AddFieldIdentifyToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :field_identify, :int
  end
end
