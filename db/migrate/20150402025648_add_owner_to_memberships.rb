class AddOwnerToMemberships < ActiveRecord::Migration
  def change
  	add_column :memberships, :owner, :boolean, :default => false
  end
end
