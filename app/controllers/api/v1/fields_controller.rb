module Api::V1
  class FieldsController < ApplicationController
    include Concerns::CheckApiDocs

    before_filter :authenticate_api_user!

    def index
      fields = collection.visible_layers_for current_user
      render json: fields
    end
  end
end