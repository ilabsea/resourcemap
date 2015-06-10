module Api::V1
  class LayerMembershipsController < ApplicationController
    include Concerns::CheckApiDocs
    include Api::JsonHelper

    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token

    def index
      layer_membership = LayerMembership.filter_layer_membership(current_user,
        params[:collection_id])
      render json: layer_membership
    end
  end
end