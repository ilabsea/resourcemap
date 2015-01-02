class RemoveFieldLanguage < ActiveRecord::Migration
  def up
  	drop_table :field_languages
  end

  def down
  	create_table :field_languages do |t|
  		t.references :language
      t.references :field
  		t.string     :code
  		t.string     :name
  		t.text       :config
  		t.timestamps  		
  	end
  end
end
