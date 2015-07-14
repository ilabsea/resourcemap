#encoding: utf-8 
class UpdateLanguagesTable < ActiveRecord::Migration
  def up
  	Language.connection.execute("update languages set name='ខ្មែរ' where id=2")
  end

  def down
  end
end
