class CreateFieldLogics < ActiveRecord::Migration
  def change
    create_table :field_logics do |t|
      t.belongs_to :field
      t.string :value
      t.belongs_to :layer

      t.timestamps
    end
  end
end
