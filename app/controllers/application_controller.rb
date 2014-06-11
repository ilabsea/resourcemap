class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery

  include Concerns::MobileDeviceDetection

  expose(:collection)
  expose(:current_user_snapshot) { UserSnapshot.for current_user, collection }
  expose(:collection_memberships) { collection.memberships.includes(:user) }
  expose(:layers) {if !current_user_snapshot.at_present? && collection then collection.layer_histories.at_date(current_user_snapshot.snapshot.date) else collection.layers end}
  expose(:layer)
  expose(:fields) {if !current_user_snapshot.at_present? && collection then collection.field_histories.at_date(current_user_snapshot.snapshot.date) else collection.fields end}
  expose(:activities) { current_user.activities }
  expose(:thresholds) { collection.thresholds.order :ord }
  expose(:threshold)
  expose(:reminders) { collection.reminders }
  expose(:reminder)

  expose(:new_search_options) do
    if current_user_snapshot.at_present?
      {current_user: current_user}
    else
      {snapshot_id: current_user_snapshot.snapshot.id, current_user_id: current_user.id}
    end
  end
  expose(:new_search) { collection.new_search new_search_options }

  rescue_from ActiveRecord::RecordNotFound do |x|
    render :file => '/error/doesnt_exist_or_unauthorized', :status => 404, :layout => true
  end

  rescue_from CanCan::AccessDenied do |exception|
    render :file => '/error/doesnt_exist_or_unauthorized', :alert => exception.message, :status => :forbidden
  end

  before_filter :set_timezone

  def set_timezone
    # current_user.time_zone #=> 'London'
    Time.zone = current_user.time_zone if current_user
  end

  def setup_guest_user
    u = User.new is_guest: true
    # Empty membership for the current collection
    # This is used in SitesPermissionController.index
    # TODO: Manage permissions passing current_ability to client
    u.memberships = [Membership.new(collection_id: collection.id)]
    @guest_user = u
  end

  def current_user
    super || @guest_user
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

  def authenticate_api_user!
    params.delete :auth_token if current_user
    head :forbidden unless current_user
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
    add_breadcrumb collection.name, collections_path + "?collection_id=#{collection.id}"
  end

  def show_properties_breadcrumb
    add_breadcrumb "Properties", collection_path(collection)
  end

  def get_user_auth_token
    render :text => current_user.authentication_token, :layout => false
  end
end
