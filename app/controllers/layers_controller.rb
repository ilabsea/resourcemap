class LayersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :except => [:index]
  before_filter :fix_field_config, only: [:create, :update]

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
        add_breadcrumb I18n.t('views.collections.tab.layers'), collection_layers_path(collection)
      end
      if current_user_snapshot.at_present?
        json = layers.includes(:fields).all.as_json(include: :fields).each { |layer|
          layer['threshold_ids'] = Layer.find(layer['id']).get_associated_threshold_ids
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

  def create
    layer = layers.new params[:layer]
    layer.user = current_user
    layer.save!
    current_user.layer_count += 1
    current_user.update_successful_outcome_status
    current_user.save!(:validate => false)
    render json: layer.as_json(include: :fields)
  end

  def update
    # FIX: For some reason using the exposed layer here results in duplicated fields being created
    layer = collection.layers.find params[:id]
    fix_layer_fields_for_update
    layer.user = current_user
    layer.update_attributes! params[:layer]   
    layer.reload
    render json: layer.as_json(include: :fields)

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

  private

  # The options come as a hash insted of a list, so we convert the hash to a list
  # Also fix hierarchy in the same way.
  def fix_field_config
    if params[:layer] && params[:layer][:fields_attributes]
      params[:layer][:fields_attributes].each do |field_idx, field|


        if field[:config]
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
              field_logic['value'] = field_logic['value'].to_i
              if field_logic['field_id']
                field_logic['field_id'].each { |field_id|
                  if field_id == ""
                    field_logic['field_id'] = nil
                  else
                    field_logic['field_id'] = field_id
                  end
                }
              end
            }    
          end

          field[:config][:range] = fix_field_config_range(field_idx,field) if field[:is_enable_range]
          
        end
      end
    end
  end

  def fix_field_config_range(field_idx,field)
    if field[:is_enable_range] == "false"
      params[:layer][:fields_attributes][field_idx][:config] = params[:layer][:fields_attributes][field_idx][:config].except(:range)
    else
      if field[:config][:range]
        if field[:config][:range][:minimum] == ""
          field[:config][:range][:minimum] = nil
        else
          field[:config][:range][:minimum] = field[:config][:range][:minimum].to_i
        end
        if field[:config][:range][:maximum] == ""
          field[:config][:range][:maximum] = nil
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
end
