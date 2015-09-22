class CreateShareNationalChannels < ActiveRecord::Migration
  def change
    create_table :share_national_channels do |t|
      t.integer :user_id, belongs_to: :users
      t.integer :collection_id , belongs_to: :collections

      t.timestamps
    end
  end

end
