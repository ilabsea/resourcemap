class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  #before_filter :prepare_for_mobile

  expose(:collections) { current_user.collections }
  expose(:collection)
  expose(:current_snapshot) { collection.snapshot_for(current_user) }
  expose(:collection_memberships) { collection.memberships.includes(:user) }
  expose(:layers) {if current_snapshot && collection then collection.layer_histories.at_date(current_snapshot.date) else collection.layers end}
  expose(:layer)
  expose(:fields) {if current_snapshot && collection then collection.field_histories.at_date(current_snapshot.date) else collection.fields end}
  expose(:activities) { current_user.activities }
  expose(:thresholds) { collection.thresholds.order :ord }
  expose(:threshold)
  expose(:reminders) { collection.reminders }
  expose(:reminder)

  rescue_from ActiveRecord::RecordNotFound do |x|
    render :file => '/error/doesnt_exist_or_unauthorized', :status => 404, :layout => true
  end

  #before_filter :prepare_for_mobile

  private

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    #request.format = :mobile if mobile_device?
  end

  def current_user_or_guest
    if user_signed_in?
      return if !current_user.try(:is_guest)
    end

    if params.has_key? "collection"
      return if !Collection.find(params["collection"]).public
      u = User.find_by_is_guest true
      sign_in :user, u
      current_user.is_login = true
      current_user.save!
    else
      if current_user.try(:is_login)
        current_user.is_login = false
        current_user.save!
      else
        sign_out :user
      end
    end
  end

  def after_sign_in_path_for(resource)
    if mobile_device?
      stored_location_for(resource) || mobile_collections_path
    else
      stored_location_for(resource) || collections_path
    end
  end

  def authenticate_collection_user!
    head :forbidden unless current_user.belongs_to?(collection)
  end

  def authenticate_collection_admin!
    head :forbidden unless current_user.admins?(collection)
  end

  def authenticate_site_user!
    head :forbidden unless current_user.belongs_to?(site.collection)
  end

  def show_collections_breadcrumb
    @show_breadcrumb = true
  end

  def show_collection_breadcrumb
    show_collections_breadcrumb
    add_breadcrumb "Collections", collections_path
    add_breadcrumb collection.name, collections_path + "?collection=#{collection.id}"
  end

  def show_properties_breadcrumb
    add_breadcrumb "Properties", collection_path(collection)
  end

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end
end
