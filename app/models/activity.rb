#encoding: UTF-8
require "csv"

class Activity < ActiveRecord::Base
  ItemTypesAndActions = {
    'collection' => %w(created imported csv_imported),
    'layer' => %w(created changed deleted),
    'site' => %w(created changed deleted)
  }
  Kinds = Activity::ItemTypesAndActions.map { |item_type, actions| actions.map { |action| "#{item_type},#{action}" } }.flatten.freeze

  belongs_to :collection
  belongs_to :user
  belongs_to :layer
  belongs_to :field
  belongs_to :site

  serialize :data

  validates_inclusion_of :item_type, :in => ItemTypesAndActions.keys
  
  
  def self.search_collection options 
     activities = Activity.order('id desc' ).includes(:site, :user, :collection, :field)
     
     activities =  activities.where(["collection_id = :collection_id",
         :collection_id => options[:id]
     ])
   
     activities = activities.where(' item_type = "site" ')
     
     case options[:type]
     
     when "month"
       current_month = DateTime.current.beginning_of_month
       activities = activities.where("created_at >= :current_month ", :current_month => current_month)
     
     when "previous_month"
       previous_month = DateTime.current - 1.month
       start_day = previous_month.beginning_of_month.beginning_of_day
       end_day  = previous_month.end_of_month.end_of_day 
       activities = activities.where(['created_at BETWEEN :start_day AND :end_day',
           :start_day => start_day, :end_day => end_day ]) 
      
     when "all"
        #nothing to do here
     when "range" 
       if !options[:from].blank? && !options[:to].blank? 
          activities = activities.where(['created_at BETWEEN :start_day AND :end_day',
                      :start_day => options[:from] , :end_day => options[:to] ])
       elsif !options[:from].blank?    
          activities = activities.where(['created_at >= :start_day',
                      :start_day => options[:from] ])
       elsif !options[:to].blank?
          activities = activities.where(['created_at <= :end_day',
                      :end_day => options[:to] ])
       else
         # just like all nothing to do
       end           
      
     end
     activities
  end
  
  def self.migrate_site_activity collection_id
    options = {
      :id => collection_id,
      :type => "all"
    }

    activities = search_collection(options) # search activities from criterias
    activities = activities.select{|activity| !activity.site.nil?} # some sites were remove but there activity log still in db
    migrate_activities(activities)   
  end
  
  def self.migrate_activities activities
    sites = {} # store unique sites from activities
    activities.each do |activity|
      sites[activity.site.id]  = activity.site
    end
    
    sites.each do |site_id, site|
      site_activities = activities.select{|activity| activity.site.id == site.id }
      migrate_activities_of_site site_activities, site
    end
  end
  
  def self.migrate_activities_of_site site_activities, site
    last_properties = site.properties
    last_lat = site.lat
    last_lng = site.lng
    last_name = site.name

    site_activities.each do |activity| 
      if(activity.action == "changed")      
            activity.data["properties"] = last_properties.dup
            activity.data["lat"]  = last_lat
            activity.data["lng"]  = last_lng
            activity.data["name"] = activity.data["name"] || last_name
            activity.save
            
          if(!activity.data["changes"]["lat"].nil? && !activity.data["changes"]["lat"].empty?)
            last_lat = activity.data["changes"]["lat"][0]
          end
          
          if(!activity.data["changes"]["lng"].nil? && !activity.data["changes"]["lng"].empty?)
            last_lng = activity.data["changes"]["lng"][0]
          end
          
          if(!activity.data["changes"]["properties"].nil? && !activity.data["changes"]["properties"].empty?)
            activity.data["changes"]["properties"][0].each do |key, value|
              last_properties[key] = value
            end
          end
      end
    end
    site_activities
  end
 
  
  def self.to_csv_file options, filename
    collection = Collection.find(options[:id])
    CSV.open(filename, 'w') do |csv|
        colunm_header = [ 
                         "User",
                         "Site",
                         "SiteCode",
                         "Lat",
                         "Lng",
                         "Date"                   
                         ]
                         
        
        column_keys = {} #column properties of csv stored in "field"
        
        collection.fields.each do |field|
          column_keys[field.id] = field.name
        end
      
        # add column properties to csv column header
        column_keys.each do |key, value|
          colunm_header << value
        end
        colunm_header << "Action"
        csv << colunm_header  
      
        
        activities = search_collection(options) # search activities from criterias
        sites = {} # store unique sites from activities
        
        activities.each do |activity|
          sites[activity.site.id]  = activity.site
        end
        
        sites.each do |site_id, site|
          properties_row = {}         
          column_keys.each do |col_id, col_name|
             properties_row[col_id.to_s] = ""
          end
          
          site_activities = activities.select{|activity| activity.site.id == site.id }  
          
          site_activities.each do |activity|   
             properties_row = properties_row.merge(activity.data["properties"] || {} )
             row = [
               activity.user.email,
               activity.data["name"] ,
               activity.site.id_with_prefix ,
               activity.data["lat"] ,
               activity.data["lng"] ,              
               activity.updated_at               
             ]            
             properties_row.each do |col_key, col_value|
               row << col_value   
             end
             
             row << activity.action
             #row << activity.description
             
             csv << row
          end
          
          #put 3 empty rows to separate each site
          number_empty_row = 1
          number_empty_row.times do
            csv << Array.new(colunm_header.size){ "" }
          end
        end
    end
  end

  def description
    case [item_type, action]
    when ['collection', 'created']
      "Collection '#{data['name']}' was created"
    when 'collection_imported'
      "Import wizard: #{sites_were_imported_text}"
    when ['collection', 'csv_imported']
      "Import CSV: #{sites_were_imported_text}"
    when ['layer', 'created']
      fields_str = data['fields'].map { |f| "#{f['name']} (#{f['code']})" }.join ', '
      str = "Layer '#{data['name']}' was created with fields: #{fields_str}"
    when ['layer', 'changed']
      layer_changed_text
    when ['layer', 'deleted']
      str = "Layer '#{data['name']}' was deleted"
    when ['site', 'created']
      "Site '#{data['name']}' was created"
    when ['site', 'changed']
      site_changed_text
    when ['site', 'deleted']
      "Site '#{data['name']}' was deleted"
    end
  end

  def item_id
    case item_type
    when 'collection'
      collection_id
    when 'layer'
      layer_id
    when 'site'
      site_id
    end
  end

  private

  def sites_were_imported_text
    sites_created_text = "#{data['sites']} site#{data['sites'] == 1 ? '' : 's'}"
    "#{sites_created_text} were imported"
  end

  def site_changed_text
    only_name_changed, changes = site_changes_text
    if only_name_changed
      "Site '#{data['name']}' was renamed to '#{data['changes']['name'][1]}'"
    else
      "Site '#{data['name']}' changed: #{changes}"
    end
  end

  def site_changes_text
    fields = collection.fields.index_by(&:es_code)
    text_changes = []
    only_name_changed = false
    
    if (change = data['changes']['name'])
      text_changes << "name changed from '#{change[0]}' to '#{change[1]}'"
      only_name_changed = true
    end

    if data['changes']['lat'] && data['changes']['lng']
      text_changes << "location changed from #{format_location data['changes'], :from} to #{format_location data['changes'], :to}"
      only_name_changed = false
    end
    
    if data['changes']['properties']
      properties = data['changes']['properties']
      
      properties[0].each do |key, old_value|
        new_value = properties[1][key]
        if new_value != old_value
          field = fields[key]
          code = field.try(:code)
          text_changes << "'#{code}' changed from #{format_value field, old_value} to #{format_value field, new_value}"
        end
      end

      properties[1].each do |key, new_value|
        if !properties[0].has_key? key
          field = fields[key]
          code = field.try(:code)
          text_changes << "'#{code}' changed from (nothing) to #{new_value.nil? ? '(nothing)' : format_value(field, new_value)}"
        end
      end

      only_name_changed = false
    end

    [only_name_changed, text_changes.join(', ')]
  end

  def layer_changed_text
    only_name_changed, changes = layer_changes_text
    if only_name_changed
      "Layer '#{data['name']}' was renamed to '#{data['changes']['name'][1]}'"
    else
      "Layer '#{data['name']}' changed: #{changes}"
    end
  end

  def layer_changes_text
    text_changes = []
    only_name_changed = false

    if (change = data['changes']['name'])
      text_changes << "name changed from '#{change[0]}' to '#{change[1]}'"
      only_name_changed = true
    end

    if data['changes']['added']
      data['changes']['added'].each do |field|
        text_changes << "#{field['kind']} field '#{field['name']}' (#{field['code']}) was added"
      end
      only_name_changed = false
    end

    if data['changes']['changed']
      data['changes']['changed'].each do |field|
        ['name', 'code', 'kind'].each do |key|
          if field[key].is_a? Array
            text_changes << "#{old_value field['kind']} field '#{old_value field['name']}' (#{old_value field['code']}) #{key} changed to '#{field[key][1]}'"
          end
        end

        if field['config'].is_a?(Array)
          old_options = (field['config'][0] || {})['options']
          new_options = (field['config'][1] || {})['options']
          if old_options != new_options
            text_changes << "#{old_value field['kind']} field '#{old_value field['name']}' (#{old_value field['code']}) options changed from #{format_options old_options} to #{format_options new_options}"
          end
        end
      end
      only_name_changed = false
    end

    if data['changes']['deleted']
      data['changes']['deleted'].each do |field|
        text_changes << "#{field['kind']} field '#{field['name']}' (#{field['code']}) was deleted"
      end
      only_name_changed = false
    end

    [only_name_changed, text_changes.join(', ')]
  end

  def old_value(value)
    value.is_a?(Array) ? value[0] : value
  end

  def format_value(field, value)
    if field && field.yes_no?
      value == 'true' || value == '1' ? 'yes' : 'no'
    elsif field && field.select_one?
      format_option field, value
    elsif field && field.select_many? && value.is_a?(Array)
      value.map { |v| format_option field, v }
    else
      value.is_a?(String) ? "'#{value}'" : value
    end
  end

  def format_option(field, value)
    option = field.config['options'].find { |o| o['id'] == value }
    option ? "#{option['label']} (#{option['code']})" : value
  end

  def format_options(options)
    (options || []).map { |option| "#{option['label']} (#{option['code']})" }
  end

  def format_location(changes, dir)
    idx = dir == :from ? 0 : 1
    lat = changes['lat'][idx]
    lng = changes['lng'][idx]
    if lat
      "(#{((lat) * 1e6).round / 1e6.to_f}, #{((lng) * 1e6).round / 1e6.to_f})"
    else
      '(nothing)'
    end
  end
end
