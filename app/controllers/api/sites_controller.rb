class Api::SitesController < ApplicationController
  include Api::JsonHelper

  # before_filter :authenticate_user!
  # before_filter :authenticate_site_user!

  skip_before_filter  :verify_authenticity_token

  expose(:site)

  def show
    current_snapshot = site.collection.snapshot_for(current_user)
    if current_snapshot
      search = site.collection.new_search snapshot_id: current_snapshot.id, current_user_id: current_user.id
    else
      search = site.collection.new_search current_user_id: current_user.id
    end

    search.id(site.id)
    @result = search.api_results[0]

    respond_to do |format|
      format.rss
      format.json { render json: site_item_json(@result) }
    end
  end

  def update
    site.user = User.first
    # site.name = params[:name]
    site.lat = params[:lat]
    site.lng = params[:lng]
    if site.valid?
      site.save!
      render json: {site: site, status: 201}
    else
      render json: site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  def destroy
    site = Site.find_by_id(params[:id])
    site.destroy
    render json: {site: site}
  end

  def create
    site_params = {}
    properties = prepare_site_property params
    site_params.merge!("name" => params[:name])
    site_params.merge!("lat" => params[:lat])
    site_params.merge!("lng" => params[:lng])
    site_params.merge!("properties" => properties)
    current_user = User.find_by_email(params[:email])
    collection = Collection.find_by_id(params[:collection_id])
    site = collection.sites.new(site_params.merge!(user: current_user))
    if site.valid?
      site.save!
      # Site::UploadUtils.uploadFile(params[:fileUpload])
      current_user.site_count += 1
      current_user.update_successful_outcome_status
      current_user.save!
      render json: {site: site, status: 201}
    end
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
end
