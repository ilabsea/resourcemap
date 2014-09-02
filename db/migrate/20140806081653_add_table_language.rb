class AddTableLanguage < ActiveRecord::Migration
  def up
  	create_table :languages do |t|
      t.string :name
      t.string :code
      t.timestamps
    end
  end

  def down
  	drop_table :languages
  end
end