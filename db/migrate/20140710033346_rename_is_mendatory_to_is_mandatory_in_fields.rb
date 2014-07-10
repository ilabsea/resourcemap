class RenameIsMendatoryToIsMandatoryInFields < ActiveRecord::Migration
  def up
  	rename_column :fields, :is_mendatory, :is_mandatory
  end

  def down
  	rename_column :fields, :is_mandatory, :is_mendatory
  end
end
