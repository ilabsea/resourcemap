class AddIsEnabledNationalGatewayToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :is_enabled_national_gateway, :boolean, :default => false
  end
end
