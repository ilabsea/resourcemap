class LayerMembership < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user

  after_save :touch_membership_lifespan
  after_destroy :touch_membership_lifespan

  def self.filter_layer_membership current_user , collection_id
    builder = LayerMembership.where(
      :collection_id => collection_id, :user_id => current_user.id) 
  end
end
