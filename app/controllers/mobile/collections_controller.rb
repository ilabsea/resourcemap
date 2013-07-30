class Mobile::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  helper_method :collections_with_layer

  expose(:collections) {
    if current_user && !current_user.is_guest
      # public collections are accesible by all users
      # here we only need the ones in which current_user is a member
      current_user.collections.reject{|c| c.id.nil?}
    else
      Collection.accessible_by(current_ability)
    end
  }

  def index
    respond_to do |format|
      format.html { render layout: 'mobile' }
      format.json { render json: collections_with_layer }
    end
  end

  private
  def collections_with_layer
    collections.map do |collection|
      attrs = collection.attributes.dup
      attrs["layers"] = collection.visible_layers_for(current_user)
      attrs
    end
  end
end

