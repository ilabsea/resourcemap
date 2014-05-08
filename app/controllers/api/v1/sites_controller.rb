module Api::V1
  class SitesController < ApplicationController
    include Concerns::CheckApiDocs

    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token

    def create
      site = collection.sites.build sanitized_site_params.merge(user: current_user)
      if site.save
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!

        render json: site, status: :created
      else
        render json: site.errors.messages, status: :unprocessable_entity
      end
    end

    private
    def sanitized_site_params
      parameters = params[:site]
      fields = collection.writable_fields_for(current_user).index_by &:es_code
      site_properties = parameters.delete("properties") || {}
      decoded_properties = {}
      site_properties.each_pair do |es_code, value|
        value = [ value, params["files"][value] ] if fields[es_code].kind_of? Field::PhotoField
        decoded_properties[es_code] = fields[es_code].decode_from_ui(value) if fields[es_code]
      end

      parameters["properties"] = decoded_properties
      parameters
    end
  end
end