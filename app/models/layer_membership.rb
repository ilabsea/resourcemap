class LayerMembership < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user

  def self.filter_layer_membership current_user , collection_id
    builder = LayerMembership.where(
      :collection_id => collection_id, :user_id => current_user.id) 
  end
end
