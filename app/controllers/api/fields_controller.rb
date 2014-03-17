class Api::FieldsController < ApplicationController
  include Concerns::CheckApiDocs

  before_filter :authenticate_api_user!

  def index
    render json: collection.writable_fields_for(current_user)
  end
end