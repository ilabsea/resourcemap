class ChangeTypeConfigInFieldHistories < ActiveRecord::Migration
  def up
  	change_column :field_histories, :config, :binary, :limit => 32.megabyte
  end

  def down
  end
end
