# == Schema Information
#
# Table name: layers
#
#  id            :integer          not null, primary key
#  collection_id :integer
#  name          :string(255)
#  public        :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ord           :integer
#

class LayersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :except => [:index, :list_layers]
  before_filter :fix_field_config, only: [:create, :update]

  # expose(:import_job) { ImportJob.last_for current_user, collection }
  # expose(:failed_import_jobs) { ImportJob.where(collection_id: collection.id).where(status: 'failed').order('id desc').page(params[:page]).per_page(10) }

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
        add_breadcrumb I18n.t('views.collections.tab.layers'), collection_layers_path(collection)
      end
      if current_user_snapshot.at_present?
        json = layers.includes(:fields).all.as_json(:include => {:fields => {except: [:updated_at, :created_at]}}).each { |layer|
          layer[:fields].each { |field|
            field['threshold_ids'] = get_associated_field_threshold_ids(field)
            field['query_ids'] = get_associated_field_query_ids(field)
            field['report_query_ids'] = get_associated_field_report_query_ids(field)
          }
          layer['threshold_ids'] = Layer.find(layer['id']).get_associated_threshold_ids
          layer['query_ids'] = Layer.find(layer['id']).get_associated_query_ids
        }
        format.json { render json:  json}
      else
        format.json {
          render json: layers
            .includes(:field_histories)
            .where("field_histories.valid_since <= :date && (:date < field_histories.valid_to || field_histories.valid_to is null)", date: current_user_snapshot.snapshot.date)
            .as_json(include: :field_histories)
          }
      end
    end
  end

  def show
    layers = Layer.where("id=?",params["id"])
    json = layers.includes(:fields).all.as_json(:include => {:fields => {except: [:updated_at, :created_at]}}).each { |layer|
      layer[:fields].each { |field|
        field['threshold_ids'] = get_associated_field_threshold_ids(field)
        field['query_ids'] = get_associated_field_query_ids(field)
        field['report_query_ids'] = get_associated_field_report_query_ids(field)
      }
      layer['threshold_ids'] = Layer.find(layer['id']).get_associated_threshold_ids
      layer['query_ids'] = Layer.find(layer['id']).get_associated_query_ids
      layer['report_query_ids'] = Layer.find(layer['id']).get_associated_report_query_ids
    }
    render :json => json[0]
  end

  def list_layers
    if current_user_snapshot.at_present?
      json = apply_limit_field(layers, 50)
      render json:  json, root: false
    else
      render json: layers
        .includes(:field_histories)
        .where("field_histories.valid_since <= :date && (:date < field_histories.valid_to || field_histories.valid_to is null)", date: current_user_snapshot.snapshot.date)
        .as_json(include: :field_histories)
    end
  end

  def create
    layer = layers.new params[:layer]
    layer.user = current_user
    layer.save!
    current_user.layer_count += 1
    current_user.update_successful_outcome_status
    current_user.save!(:validate => false)
    render json: layer.as_json(:include => {:fields => {except: [:updated_at, :created_at]}})
  end

  def update
    # FIX: For some reason using the exposed layer here results in duplicated fields being created
    layer = collection.layers.find params[:id]
    fix_layer_fields_for_update
    layer.user = current_user
    layer.update_attributes! params[:layer]
    layer.reload
    render json: layer.as_json(:include => {:fields => {except: [:updated_at, :created_at]}})

  end

  def set_order
    layer.user = current_user
    layer.update_attributes! ord: params[:ord]
    render json: layer
  end

  def destroy

    if params['threshold_ids']
      Threshold.delete(params['threshold_ids'])
      collection.recreate_index
    end

    layer.user = current_user
    layer.destroy
    head :ok
  end

  def upload_layers
    # raw_layers = File.read(params[:file].path, :encoding => 'utf-8')
    directory = "public/upload"
    path = File.join(directory, 'tmp_layers.json')
    File.open(path, "wb") { |f| f.write(params[:file].read) }
    flash[:notice] = "File uploaded"      
    redirect_to :action => "adjust_layers"
  end

  # def upload_json
  #   # debugger
  #   raw_layers = File.read(params[:file].path, :encoding => 'utf-8')
  #   all_layers = JSON.parse raw_layers
  #   all_new_layers = []
  #   all_layers.each do |l|
  #     result = layer.decode_raw_layer l
  #     new_layer = layers.new result
  #     new_layer.user = current_user
  #     # new_layer.save!
  #     # current_user.layer_count += 1
  #     # current_user.update_successful_outcome_status
  #     # current_user.save!(:validate => false)
  #     all_new_layers.push(new_layer.as_json(include: :fields))
  #   end
  #   # redirect_to action: "index"
  #   redirect_to :action => "adjust_layers"
  # end

  def adjust_layers
    # directory = "public/upload"
    # path = File.join(directory, 'tmp_layers.json')
    # raw_layers = File.read(path, :encoding => 'utf-8')
    # p raw_layers
  end

  def pending_layers
    path = File.join('public/upload', 'tmp_layers.json')
    raw_layers = File.read(path, :encoding => 'utf-8')
    all_layers = JSON.parse raw_layers
    all_new_layers = []
    all_layers.each do |l|
      result = layer.decode_raw_layer l
      new_layer = layers.new result
      new_layer.user = current_user
      # new_layer.save!
      # current_user.layer_count += 1
      # current_user.update_successful_outcome_status
      # current_user.save!(:validate => false)
      all_new_layers.push(new_layer.as_json(include: :fields))
    end
    render json: all_new_layers
  end

  def import_json
    
  end

  private

  # The options come as a hash insted of a list, so we convert the hash to a list
  # Also fix hierarchy in the same way.
  def fix_field_config
    if params[:layer] && params[:layer][:fields_attributes]
      params[:layer][:fields_attributes].each do |field_idx, field|


        if field[:config]
          if field[:config][:locations]
            field[:config][:locations] = field[:config][:locations].values
          end
          if field[:config][:options]
            field[:config][:options] = field[:config][:options].values
            field[:config][:options].each { |option| option['id'] = option['id'].to_i }
          end
          field[:config][:next_id] = field[:config][:next_id].to_i if field[:config][:next_id]
          if field[:config][:hierarchy]
            field[:config][:hierarchy] = field[:config][:hierarchy].values
            sanitize_items field[:config][:hierarchy]
          end

          if field[:is_enable_field_logic] == "false"
            params[:layer][:fields_attributes][field_idx][:config] = params[:layer][:fields_attributes][field_idx][:config].except(:field_logics)
          end
          if field[:config][:field_logics]
            field[:config][:field_logics] = field[:config][:field_logics].values
            field[:config][:field_logics].each { |field_logic|
              field_logic['id'] = field_logic['id'].to_i
              field_logic['value'] = field_logic['value']
              field_logic['field_id'] = field_logic['field_id']
            }
          else
            field[:config][:field_logics] = []
          end
          field[:config][:range] = fix_field_config_range(field_idx,field) if field[:is_enable_range]
        else
          field[:config] = {}
          field[:config][:field_logics] = []
          field[:config][:field_validations] = []
          field[:config][:range] = fix_field_config_range(field_idx, field) if field[:is_enable_range]
        end
      end
    end
  end

  def fix_field_config_range(field_idx,field)
    if field[:is_enable_range] == "false"
      params[:layer][:fields_attributes][field_idx][:config] = params[:layer][:fields_attributes][field_idx][:config].except(:range)
    else
      if field[:config][:range]
        if field[:config][:range][:minimum] == "" || field[:config][:range][:minimum].nil?
          field[:config][:range] = field[:config][:range].except(:minimum)
        else
          field[:config][:range][:minimum] = field[:config][:range][:minimum].to_i
        end
        if field[:config][:range][:maximum] == "" || field[:config][:range][:maximum].nil?
          field[:config][:range] = field[:config][:range].except(:maximum)
        else
          field[:config][:range][:maximum] = field[:config][:range][:maximum].to_i
        end
      end
    end
    return field[:config][:range]
  end

  def validate_field_logic
    field[:config][:field_logics].delete_if { |field_logic| !field_logic['layer_id'] }
    if field[:config][:field_logics].length == 0
      params[:layer][:fields_attributes][field_idx][:config] = params[:layer][:fields_attributes][field_idx][:config].except(:field_logics)
    end
  end

  def sanitize_items(items)
    items.each do |item|
      if item[:sub]
        item[:sub] = item[:sub].values
        sanitize_items item[:sub]
      end
    end
  end

  # Instead of sending the _destroy flag to destroy fields (complicates things on the client side code)
  # we check which are the current fields ids, which are the new ones and we delete those fields
  # whose ids don't show up in the new ones and then we add the _destroy flag.
  #
  # That way we preserve existing fields and we can know if their codes change, to trigger a reindex
  def fix_layer_fields_for_update
    fields = layer.fields

    fields_ids = fields.map(&:id).compact
    new_ids = params[:layer][:fields_attributes].values.map { |x| x[:id].try(:to_i) }.compact
    removed_fields_ids = fields_ids - new_ids

    max_key = params[:layer][:fields_attributes].keys.map(&:to_i).max
    max_key += 1

    removed_fields_ids.each do |id|
      params[:layer][:fields_attributes][max_key.to_s] = {id: id, _destroy: true}
      max_key += 1
    end

    params[:layer][:fields_attributes] = params[:layer][:fields_attributes].values
  end

  def get_associated_field_threshold_ids(field)
    associated_field_threshold_ids = []
    fieldID = field["id"]

    self.collection.thresholds.map { |threshold|
      threshold.conditions.map { |condition|
        conditionFieldID = condition['field'].to_i
        if fieldID == conditionFieldID
          associated_field_threshold_ids.push(threshold.id)
          break
        end
      }
    }

    associated_field_threshold_ids
  end

  def get_associated_field_query_ids(field)
    associated_field_query_ids = []
    fieldID = field["id"]

    self.collection.canned_queries.map { |query|
      query.conditions.map { |condition|
        conditionFieldID = condition['field_id'].to_i
        if fieldID == conditionFieldID
          associated_field_query_ids.push(query.id)
          break
        end
      }
    }

    associated_field_query_ids
  end

  def get_associated_field_report_query_ids(field)
    associated_field_ids = []
    fieldID = field["id"]

    self.collection.report_queries.map { |query|
      map_condition_field_ids = query.condition_fields.select{|item| item["field_id"].to_i == fieldID}
      map_group_by_field_ids = query.group_by_fields.include?(fieldID.to_s)
      map_aggregate_field_ids = query.aggregate_fields.select{|item| item["field_id"].to_i == fieldID}

      if(map_condition_field_ids.length > 0  || map_group_by_field_ids || map_aggregate_field_ids.length > 0)
        associated_field_ids.push(query.id)
      end
    }

    associated_field_ids
  end

  def apply_limit_field(layers, limit)
    json = layers.includes(:fields).all.as_json(:include => {:fields => {except: [:updated_at, :created_at]}}).each { |layer|
      total_field = layer[:fields].length
      all_fields = layer[:fields]
      layer[:fields] = layer[:fields]
      layer['total'] = total_field
      all_fields.each { |field|
        field['threshold_ids'] = get_associated_field_threshold_ids(field)
        field['query_ids'] = get_associated_field_query_ids(field)
        field['report_query_ids'] = get_associated_field_report_query_ids(field)
      }
      layer['threshold_ids'] = Layer.find(layer['id']).get_associated_threshold_ids
      layer['query_ids'] = Layer.find(layer['id']).get_associated_query_ids
      layer['report_query_ids'] = Layer.find(layer['id']).get_associated_report_query_ids
      layer['last_field_ord'] = Layer.find(layer['id']).last_field_ord
    }
    return json
  end

  def set_limit_field(layer, limit)

  end
end
