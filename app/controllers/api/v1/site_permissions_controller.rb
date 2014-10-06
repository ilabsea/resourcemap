module Api::V1
  class SitePermissionsController < ApplicationController
    include Concerns::CheckApiDocs
    include Api::JsonHelper

    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token

    def index
      membership = current_user.memberships.find{|m| m.collection_id == params[:collection_id].to_i}
      render json: membership.try(:sites_permission) || SitesPermission.no_permission
    end
  end
end