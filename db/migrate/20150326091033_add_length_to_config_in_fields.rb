class AddLengthToConfigInFields < ActiveRecord::Migration
  def change
  	change_column :fields, :config, :binary, :limit => 32.megabyte
  end
end
