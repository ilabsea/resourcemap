module Api::V1
  class SitesController < ApplicationController
    include Concerns::CheckApiDocs
    include Api::JsonHelper

    before_filter :authenticate_api_user!
    before_filter :check_user_member!
    skip_before_filter  :verify_authenticity_token
    expose(:site) { Site.find(params[:site_id] || params[:id]) }

    def index
      builder = Collection.filter_sites(params)

      sites_size = builder.size
      sites_by_page  = Collection.filter_page_order_by_name(params[:limit], params[:offset], builder)
      render :json => {:sites => sites_by_page, :total => sites_size}
    end

    def show
      search = new_search

      search.id params[:id]
      result = search.ui_results.first['_source'] rescue {}
      render json: result
    end

    def update
      site.attributes = sanitized_site_params(false).merge(user: current_user)
      if site.valid?
        site.save!
        if params[:photosToRemove]
          Site::UploadUtils.purgePhotos(params[:photosToRemove])
        end
        render json: site, :layout => false
      else
        render json: site.errors.messages, status: :unprocessable_entity, :layout => false
      end
    end

    def create
      site = build_site
      create_state = site.id ? false : true #to create or update
      if site.save
        if create_state
          current_user.site_count += 1
          current_user.update_successful_outcome_status
          current_user.save!(:validate => false)
        end
        render json: site, status: :created
      else
        render json: site.errors.messages, status: :unprocessable_entity
      end
    end

    def visible_layers_for
      layers = []
      if site.collection.site_ids_permission(current_user).include? site.id
        target_fields = fields.includes(:layer).all
        layers = target_fields.map(&:layer).uniq.map do |layer|
          {
            id: layer.id,
            name: layer.name,
            ord: layer.ord,
          }
        end
        if site.collection.site_ids_write_permission(current_user).include? site.id
          layers.each do |layer|
            layer[:fields] = target_fields.select { |field| field.layer_id == layer[:id] }
            layer[:fields].map! do |field|
              {
                id: field.es_code,
                name: field.name,
                code: field.code,
                kind: field.kind,
                config: field.config,
                ord: field.ord,
                is_mandatory: field.is_mandatory,
                is_enable_field_logic: field.is_enable_field_logic,
                writeable: true
              }
            end
          end
        elsif site.collection.site_ids_read_permission(current_user).include? site.id
          layers.each do |layer|
            layer[:fields] = target_fields.select { |field| field.layer_id == layer[:id] }
            layer[:fields].map! do |field|
              {
                id: field.es_code,
                name: field.name,
                code: field.code,
                kind: field.kind,
                config: field.config,
                ord: field.ord,
                is_mandatory: field.is_mandatory,
                is_enable_field_logic: field.is_enable_field_logic,
                writeable: false
              }
            end
          end
        end
        layers.sort! { |x, y| x[:ord] <=> y[:ord] }
      else
        layers = site.collection.visible_layers_for(current_user)
      end
      render json: layers
    end

    def prepare_site_property params
      properties = {}
      conflict_state_id = Field.find_by_code("con_state").id.to_s
      conflict_type_id = Field.find_by_code("con_type").id.to_s
      conflict_intensity_id = Field.find_by_code("con_intensity").id.to_s
      properties.merge!(conflict_state_id => params[:conflict_state])
      properties.merge!(conflict_type_id => params[:conflict_type])
      properties.merge!(conflict_intensity_id => params[:conflict_intensity])

      return properties
    end

    private
    def sanitized_site_params new_record
      parameters = params[:site]

      result = new_record ? {} : site.filter_site_by_id(params[:id])

      fields = collection.fields.index_by &:es_code
      site_properties = parameters.delete("properties") || {}

      files = parameters.delete("files") || {}
      
      decoded_properties = new_record ? {} : result.properties
      site_properties.each_pair do |es_code, value|
        value = [ value, files[value] ] if fields[es_code].kind_of? Field::PhotoField
        decoded_properties[es_code] = fields[es_code].decode_from_ui(value) if fields[es_code]
      end

      parameters["properties"] = decoded_properties
      parameters
    end

    def build_site
      site = collection.is_site_exist? params[:site][:device_id], params[:site][:external_id] if params[:site][:device_id]
      if site
        params[:id] = site.id
        site.attributes = sanitized_site_params(false).merge(user: current_user)
      else
        site = collection.sites.build sanitized_site_params(true).merge(user: current_user)
      end
      return site
    end

    def check_user_member!
      collection = Collection.find_by_id(params[:collection_id])
      if (current_user.collections.map(&:id).include?(params["collection_id"].to_i))
        return true
      else
        return head 403
      end
    end

  end
end