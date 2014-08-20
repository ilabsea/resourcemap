class AddFieldByLanguage < ActiveRecord::Migration
  def up
  	create_table :field_languages do |t|
  		t.references :language
      t.references :field
  		t.string     :code
  		t.string     :name
  		t.text       :config
  		t.timestamps  		
  	end
  end

  def down
  	drop_table :field_languages
  end
end