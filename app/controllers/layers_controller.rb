class LayersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :except => [:index]
  before_filter :fix_field_config, only: [:create, :update]

  def index
    layers # signal that layers will be used on this page (loaded by ajax later)
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Layers", collection_layers_path(collection)
      end
      format.json { render_json collection.layers_to_json(current_user_snapshot.at_present?, current_user) }
    end
  end

  def create
    layer = layers.new params[:layer]
    layer.collection_id = params[:collection_id]
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
    fix_layer_fields_for_update layer
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

  def upload_layers
    path = File.join('public', 'tmp_layers.json')
    content = params[:file].read
    File.open(path, "wb") { |f| f.write(content) }
    begin
      layers = JSON.parse content
      flash[:notice] = "File uploaded"
      redirect_to :action => "adjust_layers"
    rescue Exception => e
      flash[:alert] = "Invalid file content"
      redirect_to :action => "index"
    end

  end

  def adjust_layers
    show_collection_breadcrumb
    add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
    add_breadcrumb I18n.t('views.collections.tab.layers'), collection_layers_path(collection)    
  end

  def pending_layers
    path = File.join('public', 'tmp_layers.json')
    all_new_layers = []
    if File.exist?(path)
      raw_layers = File.read(path, :encoding => 'utf-8')
      all_layers = JSON.parse raw_layers
      File.delete(path)
      all_layers.each do |l|
        result = layer.decode_raw_layer l
        new_layer = layers.new result
        new_layer.user = current_user
        all_new_layers.push(new_layer.as_json(include: :fields.as_json(:except => [:id]), :except => [:id, :ord]))
      end
    end
    render json: all_new_layers
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
              field_logic['value'] = field_logic['value'].to_i
              if field_logic['field_id']
                
                if field_logic['field_id'] == ""
                  field_logic['field_id'] = nil
                end
              end         
            }    
          end

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
          field[:config][:range][:minimum] = field[:config][:range][:minimum].to_f
        end
        if field[:config][:range][:maximum] == "" || field[:config][:range][:maximum].nil?
          field[:config][:range] = field[:config][:range].except(:maximum)
        else
          field[:config][:range][:maximum] = field[:config][:range][:maximum].to_f
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
  def fix_layer_fields_for_update layer
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

end
