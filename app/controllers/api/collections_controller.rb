class Api::CollectionsController < ApplicationController
  include Api::JsonHelper
  include Api::GeoJsonHelper
  include Concerns::CheckApiDocs

  before_filter :authenticate_api_user!
  skip_before_filter  :verify_authenticity_token

  def index
    render json: current_user.collections
  end

  def show
    options = [:sort]

    if params[:format] == 'csv' || params[:page] == 'all'
      options << :all
      params.delete(:page)
    else
      options << :page
    end

    @results = perform_search *options

    respond_to do |format|
      format.rss { render :show, layout: false }
      format.csv { collection_csv(collection, @results) }
      format.json { render json: collection_json(collection, @results) }
      format.kml { collection_kml(collection, @results) }
    end
  end

  def sample_csv
    respond_to do |format|
      format.csv { collection_sample_csv(collection) }
    end
  end

  def collection_sample_csv(collection)
    sample_csv = collection.sample_csv current_user
    send_data sample_csv, type: 'text/csv', filename: "#{collection.name}_sites.csv"
  end

  def count
    render json: perform_search(:count).total
  end

  def geo_json
    @results = perform_search :page, :sort, :require_location
    render json: collection_geo_json(collection, @results)
  end

  def update_sites
    index = 0
    array_site_ids = params[:site_id].split(",")
    array_user_email = params[:user_email].split(",")
    array_site_ids.each do |el|
      site = Site.find_by_id(el)
      site.user = User.find_by_email(array_user_email[index])
      site.user = User.first
      site.lat = params[:lat]
      site.lng = params[:lng]
      if site.valid?
        site.save!
      else
        render json: site.errors.messages, status: :unprocessable_entity, :layout => false
      end
      index = index + 1
    end
    render json: {status: 201}
  end

  def get_fields
    fields = Collection.find(params[:id]).fields
    list = []
    fields.each do |f|
      obj = {}
      obj["code"] = f.code
      obj["id"] = f.id
      obj["name"] = f.name
      obj["kind"] = f.kind
      obj["options"] = f.config["options"] if f.config["options"]
      list.push obj
    end
    render :json => list.to_json
  end

  def get_sites_conflict
    if params[:con_type]
      sites = []
      con_type = params[:con_type].split(",")
      collection = Collection.find_by_id(params[:id])
      properties = collection.fields.find_by_code(params[:field_code]).id
      if (params[:from].blank? && params[:to].blank?)
        from = parse_date_format("#{Time.now.mon}/01/#{Time.now.year}") - 1
        to = parse_date_format("#{Time.now.mon}/30/#{Time.now.year}").end_of_month + 1
        tmp_sites = Collection.find(params[:id]).sites.where(:created_at => from..to).each do |x|
          con_type.each do |el|
            if x.properties["#{properties}"] == el.to_i
              sites << x
            end
          end
        end
      else
        from = parse_date_format(params[:from]) - 1
        to = parse_date_format(params[:to]) + 1
        tmp_sites = Collection.find(params[:id]).sites.where(:created_at => from..to).each do |x|
          con_type.each do |el|
            if x.properties["#{properties}"] == el.to_i
              sites << x
            end
          end
        end
      end  
    else
      sites = Collection.find(params[:id]).sites
    end
    render :json => sites
  end

  def get_some_sites
    site_ids = params[:sites]
    sites = Site.where("id in (" + site_ids + ")")
    render :json => sites
  end

  def parse_date_format date 
    array_date = date.split("-")
    return Date.new(array_date[2].to_i, array_date[0].to_i, array_date[1].to_i)
  end

  private

  def perform_search(*options)
    except_params = [:action, :controller, :format, :id, :updated_since, :search, :box, :lat, :lng, :radius]

    search = new_search

    search.use_codes_instead_of_es_codes

    if options.include? :page
      search.page params[:page].to_i if params[:page]
      except_params << :page
    elsif options.include? :count
      search.offset 0
      search.limit 0
    elsif options.include? :all
      search.unlimited
    end

    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search]
    search.box *valid_box_coordinates if params[:box]

    if params[:lat] || params[:lng] || params[:radius]
      [:lat, :lng, :radius].each do |key|
        raise "Missing '#{key}' parameter" unless params[key]
        raise "Missing '#{key}' value" unless !params[key].blank?

      end
      search.radius params[:lat], params[:lng], params[:radius]
    end

    if options.include? :require_location
      search.require_location
    end

    if options.include? :sort
      search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
      except_params << :sort
      except_params << :sort_direction
    end

    search.where params.except(*except_params)
    search.api_results
  end

  def valid_box_coordinates
    coords = params[:box].split ','
    raise "Expected the 'box' parameter to be four comma-separated numbers" if coords.length != 4

    coords.each_with_index do |coord, i|
      Float(coord) rescue raise "Expected #{(i + 1).ordinalize} value of 'box' parameter to be a number, not '#{coord}'"
    end

    coords
  end

  def collection_csv(collection, results)
    sites_csv = collection.to_csv results, current_user
    send_data sites_csv, type: 'text/csv', filename: "#{collection.name}_sites.csv"
  end

  def collection_kml(collection, results)
    sites_kml = collection.to_kml results
    send_data sites_kml, type: 'application/vnd.google-earth.kml+xml', filename: "#{collection.name}_sites.kml"
  end


end
