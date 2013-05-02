class Mobile::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  def index
    respond_to do |format|
      format.html { render layout: 'mobile' }
      collections_with_layer = []
      collections.all.each do |collection|
        attrs = collection.attributes
        attrs["layers"] = collection.visible_layers_for(current_user)
        collections_with_layer = collections_with_layer + [attrs]
      end
      format.json {render json: collections_with_layer}
    end
  end
end

