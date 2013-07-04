class Mobile::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  helper_method :collections_with_layer

  def index
    respond_to do |format|
      format.html { render layout: 'mobile' }
      format.json { render json: collections_with_layer }
    end
  end

  private
  def collections_with_layer
    collections.all.map do |collection|
      attrs = collection.attributes.dup
      attrs["layers"] = collection.visible_layers_for(current_user)
      attrs
    end
  end
end

