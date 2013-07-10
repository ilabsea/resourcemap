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
    # site.properties_will_change!
    site.name = params[:name]
    site.lat = params[:lat]
    site.lng = params[:lng]
    if site.valid?
     # Site::UploadUtils.uploadFile(params[:fileUpload])
      site.save!
      render json: {site: site, status: 201}
    else
      render json: site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end
end
