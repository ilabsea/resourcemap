# == Schema Information
#
# Table name: collections
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  description           :text
#  public                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  lat                   :decimal(10, 6)
#  lng                   :decimal(10, 6)
#  min_lat               :decimal(10, 6)
#  min_lng               :decimal(10, 6)
#  max_lat               :decimal(10, 6)
#  max_lng               :decimal(10, 6)
#  icon                  :string(255)
#  quota                 :integer          default(0)
#  is_aggregator         :boolean          default(FALSE)
#  print_template        :text
#  is_published_template :boolean          default(TRUE)
#

class CollectionsController < ApplicationController
  before_filter :setup_guest_user, :if => Proc.new { collection }
  before_filter :authenticate_user!, :except => [:render_breadcrumbs, :index, :alerted_collections], :unless => Proc.new { collection }

  authorize_resource :except => [:render_breadcrumbs, :my_membership], :decent_exposure => true, :id_param => :collection_id

  expose(:collections){
    if current_user && !current_user.is_guest
      # public collections are accesible by all users
      # here we only need the ones in which current_user is a member
      current_user.collections
    else
      Collection.all
    end
  }

  expose(:collections_with_snapshot) { select_each_snapshot(collections) }

  before_filter :show_collections_breadcrumb, :only => [:index, :new]
  before_filter :show_collection_breadcrumb, :except => [:index, :new, :create, :render_breadcrumbs]
  before_filter :show_properties_breadcrumb, :only => [:upload_members, :members, :settings, :reminders, :quotas, :can_queries]

  expose(:import_job) { ImportJob.last_for current_user, collection }
  expose(:failed_import_jobs) { ImportJob.where(collection_id: collection.id).where(status: 'failed').order('id desc').page(params[:page]).per_page(10) }

  def my_membership
    collection = Collection.find params[:collection_id]
    member = collection.memberships.find_by_user_id current_user.id
    render :json => member
  end

  def index
    if params[:name].present?
      render json: Collection.where("name like ?", "%#{params[:name]}%") if params[:name].present?
    else
      add_breadcrumb I18n.t('views.collections.index.collections'), 'javascript:window.model.goToRoot()'

      if current_user.is_guest
        if params[:collection_id] && !collection.public?
          flash[:error] = "You need to sign in order to view this collection"
          redirect_to new_user_session_url
          return
        end
        collections = Collection.public_collections
      else
        collections = current_user.collections.reject{|c| c.id.nil?}
      end

      respond_to do |format|
        format.html
        format.json { render json:  collections}
      end
    end
  end

  def render_breadcrumbs
    add_breadcrumb I18n.t('views.collections.index.collections'), 'javascript:window.model.goToRoot()' if current_user && !current_user.is_guest
    if params.has_key? :collection_id
      add_breadcrumb collection.name, 'javascript:window.model.exitSite()'
      if params.has_key? :site_id
        add_breadcrumb params[:site_name], '#'
      end
    end
    render :layout => false
  end

  def new
    add_breadcrumb I18n.t('views.collections.index.collections'), collections_path
    add_breadcrumb I18n.t('views.collections.form.create_new_collection'), nil
  end

  def create
    if current_user.create_collection collection
      current_user.collection_count += 1
      current_user.update_successful_outcome_status
      current_user.save!(:validate => false)
      redirect_to collection_path(collection), notice: I18n.t('views.collections.form.collection_created', name: collection.name)
    else
      render :new
    end
  end

  def update
    if collection.update_attributes params[:collection]
      collection.recreate_index
      tab_url = params[:tab] == "print" ? print_template_collection_path(collection) : collection_settings_path(collection)
      redirect_to tab_url, notice: I18n.t('views.collections.form.collection_updated', name: collection.name)
    else
      template = params[:tab] == "print" ? :print_template : :settings
      render template
    end
  end

  def show
    @snapshot = Snapshot.new
    add_breadcrumb I18n.t('views.collections.index.properties'), '#'
    respond_to do |format|
      format.html
      format.json { render json: collection }
    end
  end

  def upload_members
    add_breadcrumb I18n.t('views.collections.tab.members'), collection_upload_members_path(collection)
  end

  def members
    add_breadcrumb I18n.t('views.collections.tab.members'), collection_members_path(collection)
  end

  def upload_members
    add_breadcrumb I18n.t('views.collections.tab.upload_members'), collection_members_path(collection)
  end

  def reminders
    add_breadcrumb I18n.t('views.collections.tab.reminders'), collection_reminders_path(collection)
  end

  def settings
    add_breadcrumb I18n.t('views.collections.tab.settings'), collection_settings_path(collection)
  end

  def quotas
    add_breadcrumb I18n.t('views.collections.tab.quotas'), collection_settings_path(collection)
  end

  def can_queries
    add_breadcrumb "Can queries", collection_can_queries_path(collection)
  end

  def destroy
    if params[:only_sites]
      collection.delete_sites_and_activities
      redirect_to collection_path(collection), notice: I18n.t('views.collections.form.sites_deleted', name: collection.name)
    else
      collection.update_activities
      collection.destroy
      collection.create_deleted_activity(current_user)
      redirect_to collections_path, notice: I18n.t('views.collections.form.collection_deleted', name: collection.name)
    end
  end

  def csv_template
    send_data collection.csv_template, type: 'text/csv', filename: "collection_sites_template.csv"
  end

  def upload_csv
    collection.import_csv current_user, params[:file].read
    redirect_to collections_path
  end

  def create_snapshot
    @snapshot = Snapshot.create(date: Time.now, name: params[:snapshot][:name], collection: collection)
    if @snapshot.valid?
      redirect_to collection_path(collection), notice: I18n.t('views.collections.form.snapshot_created', name: params[:name])
    else
      flash[:error] = I18n.t('views.collections.form.snapshot_could_not_be_created', errors: @snapshot.errors.to_a.join(", "))
      redirect_to collection_path(collection)
    end
  end

  def unload_current_snapshot
    loaded_snapshot = current_user_snapshot.snapshot
    current_user_snapshot.go_back_to_present!

    respond_to do |format|
      format.html {
        flash[:notice] = I18n.t('views.collections.form.snapshot_unloaded', name: loaded_snapshot.name) if loaded_snapshot if loaded_snapshot
        redirect_to  collection_path(collection) }
      format.json { render json: :ok }
    end
  end

  def load_snapshot
    if current_user_snapshot.go_to!(params[:name])
      redirect_to collection_path(collection), notice: I18n.t('views.collections.form.snapshot_loaded', name: params[:name])
    end
  end

  def max_value_of_property
    render json: collection.max_value_of_property(params[:property])
  end

  def select_each_snapshot(collections)
    collections_with_snapshot = []
    collections.each do |collection|
      attrs = collection.attributes
      # If user is guest (=> current_user will be nil) she will not be able to load a snapshot. At least for the moment
      attrs["snapshot_name"] = collection.snapshot_for(current_user).try(:name) rescue nil
      collections_with_snapshot = collections_with_snapshot + [attrs]
    end
    collections_with_snapshot
  end

  def sites_by_term
    search = new_search

    search.full_text_search params[:term] if params[:term]
    search.alerted_search params[:_alert] if params[:_alert]
    # search.select_fields(['id', 'name', 'properties'])
    # search.apply_queries

    results = search.results.map{ |item| item["_source"]["properties"]}
    results.each do |item|
      item[:value] = item["name"]
    end

    render json: results
  end


  def search
    search = new_search

    formula = params[:formula].downcase if params[:formula].present?

    search.set_formula formula if formula.present?
    search.full_text_search params[:search]
    search.offset params[:offset]
    search.limit params[:limit]
    search.alerted_search params[:_alert] if params[:_alert]
    search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
    search.hierarchy params[:hierarchy_code], params[:hierarchy_value] if params[:hierarchy_code]
    search.my_site_search current_user.id unless current_user.can_view_other? params[:collection_id]
    search.where params.except(:action, :controller, :format, :id, :collection_id, :search, :limit, :offset, :sort, :sort_direction, :hierarchy_code, :hierarchy_value, :_alert, :formula)

    results = search.results.map do |result|
      source = result['_source']

      obj = {}
      obj[:id] = source['id']
      obj[:name] = source['name']
      obj[:icon] = source['icon']
      obj[:color] = source['color']
      obj[:created_at] = Site.parse_time(source['created_at'])
      obj[:updated_at] = Site.parse_time(source['updated_at'])
      obj[:start_entry_date] = Site.parse_time(source['start_entry_date']).strftime("%d/%m/%Y %H:%M:%S") if source['start_entry_date'].present?
      obj[:end_entry_date] = Site.parse_time(source['end_entry_date']).strftime("%d/%m/%Y %H:%M:%S") if source['end_entry_date'].present?

      if source['location']
        obj[:lat] = source['location']['lat']
        obj[:lng] = source['location']['lon']
      end

      if source['properties']
        obj[:properties] = source['properties']
      end

      obj
    end
    render json: results
  end

  def decode_hierarchy_csv
    csv_string = File.read(params[:file].path, :encoding => 'utf-8')
    @hierarchy = collection.decode_hierarchy_csv(csv_string)
    @hierarchy_errors = CollectionsController.generate_error_description_list(@hierarchy)
    render layout: false
  end

  def decode_location_csv
    csv_string = File.read(params[:file].path, :encoding => 'utf-8')

    @locations = collection.decode_location_csv(csv_string)
    @locations_errors = CollectionsController.generate_error_description_location(@locations)
    render layout: false
  end

  def self.generate_error_description_location(locations_csv)
    locations_errors = []
    locations_csv.each do |item|
      message = ""
      if item[:error]
        message << "Error: #{item[:error]}"
        message << " " + item[:error_description] if item[:error_description]
        message << " in line #{item[:order]}." if item[:order]
      end

      locations_errors << message if !message.blank?
    end
    locations_errors.join("<br/>").to_s
  end

  def self.generate_error_description_list(hierarchy_csv)
    hierarchy_errors = []
    hierarchy_csv.each do |item|
      message = ""
      if item[:error]
        message << "Error: #{item[:error]}"
        message << " " + item[:error_description] if item[:error_description]
        message << " in line #{item[:order]}." if item[:order]
      end

      hierarchy_errors << message if !message.blank?
    end
    hierarchy_errors.join("<br/>").to_s
  end

  def recreate_index
    render json: collection.recreate_index
  end

  def register_gateways
    channels = []
    channels = Channel.find params[:gateways] if params[:gateways].present?
    collection.channels = channels
    render json: collection.as_json
  end

  def message_quota
    date = Date.today
    case params[:filter_type]
    when "week"
      start_date = date - 7
    when "month"
      start_date = date.prev_month
    else
      start_date = date.prev_year
    end
    ms = collection.messages.where("is_send = true and created_at between ? and ?", start_date, Time.now)
    render json: {status: 200, remain_quota: collection.quota, sended_message: ms.length }
  end

  def alerted_collections
    collections = Collection.find_all_by_id params[:ids]
    ids = collections.map do |c|
      s = c.new_search
      s.alerted_search true
      # s.apply_queries
      c.id if s.results.length > 0
    end
    render json: ids.compact
  end

  def send_new_member_sms
    random_code = (0..3).map{(rand(9))}.join
    method = Channel.nuntium_info_methods
    collection = Collection.find_by_id(params[:collection_id])
    if channel = collection.channels.first
      channel_detail = channel.as_json(methods: method)
      if channel_detail[:client_connected]
        SmsNuntium.notify_sms [params[:phone_number]], "Your single-use Resource Map pin code is #{random_code}", channel.nuntium_channel_name, nil
        render json: {status: 200, secret_code: random_code}
      else
        render json: {status: 'channel_disconnected', notice: 'The channel is disconnected.'}
      end
    else
      render json: {status: 'no_channel', notice: 'There is no channel on the collection.'}
    end
  end

  def sites_info
    options = new_search_options

    total = collection.elasticsearch_count
    no_location = collection.elasticsearch_count do
      {
        query: {
          filtered: {
            filter: {
              not: {
                filter: {
                  exists: {field: :location}
                }
              }
            }
          }
        }
      }
    end

    info = {}
    info[:total] = total
    info[:no_location] = no_location > 0
    info[:new_site_properties] = collection.new_site_properties

    render json: info
  end

  def print_template
    @fieldCodes = collection.fields.map{|f| f.code}
  end

  def copy
    new_collection = collection.copy(current_user.id, params["new_collection_name"])
    render json: new_collection
  end
end
