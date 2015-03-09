# == Schema Information
#
# Table name: sites
#
#  id               :integer          not null, primary key
#  collection_id    :integer
#  name             :string(255)
#  lat              :decimal(10, 6)
#  lng              :decimal(10, 6)
#  parent_id        :integer
#  hierarchy        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  properties       :text
#  location_mode    :string(10)       default("automatic")
#  id_with_prefix   :string(255)
#  uuid             :string(255)
#  device_id        :string(255)
#  external_id      :string(255)
#  start_entry_date :datetime         default(2015-08-14 02:57:03 UTC)
#  end_entry_date   :datetime         default(2015-08-14 02:57:03 UTC)
#  user_id          :integer
#

class SitesController < ApplicationController
  before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :except => [:index, :search, :search_alert_site, :view_photo, :share], :unless => Proc.new { collection && collection.public }

  authorize_resource :only => [:index, :search, :search_alert_site], :decent_exposure => true

  expose(:sites) {if !current_user_snapshot.at_present? && collection then collection.site_histories.at_date(current_user_snapshot.snapshot.date) else collection.sites end}
  expose(:site) { Site.find(params[:site_id] || params[:id]) }

  def index
    search = new_search
    search.name_start_with params[:name] if params[:name].present?
    search.alerted_search params[:_alert] if params[:_alert] == "true"
    search.my_site_search current_user.id if !current_user.is_guest && !current_user.can_view_other?(params[:collection_id])
    search.offset params[:offset]
    search.limit params[:limit]

    render json: search.ui_results.map { |x| x['_source'] }
  end

  def share
    if collection.is_published_template
      @site = collection.sites.find_by_uuid(params[:id])
      render layout: "print_template"
    else
      raise CanCan::AccessDenied
    end
  end

  def show
    search = new_search
    search.id params[:id]
    # If site does not exists, return empty objects
    result = search.ui_results.first['_source'] rescue {}
    # result = search.ui_results.first['_source']
    render json: result
  end

  def create
    site_params = JSON.parse params[:site]
    ui_attributes = prepare_from_ui(site_params)
    site = collection.sites.new(ui_attributes.merge(user: current_user))
    site.user = current_user

    site_aggregator = SiteAggregator.new(site)

    if site_aggregator.save
      render json: site_aggregator.site, :layout => false
    else
      render json: site_aggregator.site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  def update
    site_params = JSON.parse params[:site]
    site.properties_will_change!
    site.attributes = prepare_from_ui(site_params)

    site_aggregator = SiteAggregator.new(site)
    if site_aggregator.save
      Site::UploadUtils.purgePhotos(params[:photosToRemove]) if params[:photosToRemove]
      render json: site_aggregator.site, :layout => false
    else
      render json: site_aggregator.site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  def update_property
    field = site.collection.fields.where_es_code_is params[:es_code]
    if not site.collection.site_ids_permission(current_user).include? site.id
      return head :forbidden unless current_user.can_write_field? field, site.collection, params[:es_code]
    end

    site.user = current_user
    site.properties_will_change!

    site.properties[params[:es_code]] = field.decode_from_ui(params[:value])
    site_aggregator = SiteAggregator.new(site)

    if site_aggregator.save
      render json: site_aggregator.site, :status => 200, :layout => false
    else
      error_message = site_aggregator.site.errors.messages[:properties][0]
      render json: {:error_message => error_message}, status: :unprocessable_entity, :layout => false
    end
  end

  def search
    zoom = params[:z].to_i

    if params[:collection_ids].is_a? String
      collection_ids_array = params[:collection_ids].split ","
    elsif params[:collection_ids].is_a? Array
      collection_ids_array = params[:collection_ids]
    end

    search = MapSearch.new collection_ids_array, user: current_user

    formula = params[:formula].downcase if params[:formula].present?

    search.set_formula formula if formula.present?
    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.alerted_search params[:_alert] if params[:_alert].present?

    if current_user && collection_ids_array.length == 1 && !current_user.can_view_other?(collection_ids_array[0])
      search.my_site_search current_user.id
    end

    if params[:selected_hierarchy_id].present?
      search.selected_hierarchy params[:hierarchy_code], Field.find(params[:hierarchy_code]).descendants_of_in_hierarchy(params[:selected_hierarchy_id])
    end

    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :search, :hierarchy_code, :selected_hierarchies, :_alert, :formula)

    render_json search.results, :root => false
  end

  # TODO remove this unuse function
  def search_by_collection collection_id, params
    zoom = params[:z].to_i
    search = MapSearch.new [collection_id], user: current_user

    formula = params[:formula].downcase if params[:formula].present?

    search.set_formula formula if formula.present?
    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.alerted_search params[:_alert] if params[:_alert].present?
    search.my_site_search current_user.id if current_user && !current_user.can_view_other?(collection_id)
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end

    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :search, :hierarchy_code, :selected_hierarchies, :_alert, :formula)

    search.prepare_filter
    # search.apply_queries

    return search.results
  end

  def search_alert_site
    if params[:collection_ids]
      data = []
      params[:collection_ids].each do |id|
        result = search_alert_site_by_collection id, params
        data.concat result
      end
      render json: data
    else
      render json: []
    end
  end

  def search_alert_site_by_collection collection_id, params
    zoom = params[:z].to_i

    search = MapSearch.new [collection_id], user: current_user

    formula = params[:formula].downcase if params[:formula].present?

    search.set_formula formula if formula.present?
    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.full_text_search params[:search] if params[:search].present?
    # search.alerted_search params[:_alert] if params[:_alert].present?
    search.my_site_search current_user.id if current_user && !current_user.can_view_other?(collection_id)
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :search, :hierarchy_code, :selected_hierarchies, :_alert, :formula)

    # search.apply_queries
    # search.prepare_filter
    return search.sites_json
  end

  def search_alert_site
    zoom = params[:z].to_i

    search = MapSearch.new params[:collection_ids], user: current_user

    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.alerted_search params[:_alert] if params[:_alert].present?
    search.location_missing if params[:location_missing].present?
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search, :location_missing, :hierarchy_code, :selected_hierarchies, :_alert)

    search.apply_queries
    render json: search.sites_json    
  end

  def destroy
    site.user = current_user
    Site::UploadUtils.purgeUploadedPhotos(site)
    site.destroy
    render json: site
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

  def view_photo
    site = Site.find_by_uuid(params["uuid"])
    if site
      site.properties.each do |key, value|
        field = Field.find key
        if site.uuid == params["uuid"] and field.kind == "photo" and value == params["file_name"]
          send_file "#{Rails.root}/public/photo_field/#{value}", type: 'image/png', disposition: 'inline'
        end
      end
    else
      render :text => "File not found", :status => 404
    end
  end

  private

  def prepare_from_ui(parameters)
    fields = collection.fields.index_by(&:es_code)
    decoded_properties = {}
    site_properties = parameters.delete("properties") || {}
    files = params[:fileUpload] || {}

    site_properties.each_pair do |es_code, value|
      value = [ value, files[value] ] if fields[es_code].kind == 'photo'
      decoded_properties[es_code] = fields[es_code].decode_from_ui(value)
    end

    parameters["properties"] = decoded_properties unless decoded_properties.blank?
    parameters
  end
end
