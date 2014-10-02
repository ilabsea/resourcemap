module Api::V1
  class SitesController < ApplicationController
    include Concerns::CheckApiDocs
    include Api::JsonHelper

    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token
    expose(:site) { Site.find(params[:site_id] || params[:id]) }

    def index
      search = new_search

      search.my_site_search current_user.id unless current_user.can_view_other? params[:collection_id]
      search.offset params[:offset]
      search.limit params[:limit]

      sites_size = search.results.total

      render :json =>{:sites => search.ui_results.map { |x| x['_source'] }, :total => sites_size}
    end

    def alerted_to_reporters
      collection_ids = current_user.collections.map{|collection| collection.id }

      search = MapSearch.new collection_ids, user: current_user
      search.zoom = 0

      search.alerted_search true
      search.alerted_to_reporter true
      search.my_site_search current_user.id if current_user
      search.after params[:date]
      search.sort_by_updated_at
      search.offset 0
      search.limit 50
      search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :search, :hierarchy_code, :selected_hierarchies, :_alert, :date)

      render json: search.sites_json
    end

    def show
      search = new_search
      search.id(site.id)
      @result = search.api_opt_results[0]

      respond_to do |format|
        format.json { render json:  site_item_json(@result)}
      end
    end

    def update
      site.attributes = sanitized_site_params(false)
      site_aggregator = SiteAggregator.new(site)
      if site_aggregator.save
        if params[:photosToRemove]
          Site::UploadUtils.purgePhotos(params[:photosToRemove])
        end
        render json: site_aggregator.site, :layout => false
      else
        render json: site_aggregator.site.errors.messages, status: :unprocessable_entity, :layout => false
      end
    end

    def create

      site = build_site
      create_state = site.id ? false : true #to create or update
      site.user = current_user
      site_aggregator = SiteAggregator.new(site)
      site = collection.sites.build sanitized_site_params(true).merge(user: current_user)
      if site.save
        current_user.site_count += 1
        current_user.update_successful_outcome_status
        current_user.save!(:validate => false)

      if site_aggregator.save
        render json: site_aggregator.site, status: :created
      else
        render json: site_aggregator.site.errors.messages, status: :unprocessable_entity
      end
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
        #parse date from formate %m%d%Y to %d%m%Y for the phone_gap data old version
        if fields[es_code]
          if fields[es_code].kind == 'date' &&  value &&  value != '' && !params[:rm_wfp_version]
            value = Time.strptime(value, '%m/%d/%Y')
            value = "#{value.day}/#{value.month}/#{value.year}"
          end
          decoded_properties[es_code] = fields[es_code].decode_from_ui(value)
        end

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

  end
end
