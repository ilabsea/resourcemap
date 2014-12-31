# == Schema Information
#
# Table name: fields
#
#  id                       :integer          not null, primary key
#  collection_id            :integer
#  layer_id                 :integer
#  name                     :string(255)
#  code                     :string(255)
#  kind                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  config                   :binary(214748364
#  ord                      :integer
#  metadata                 :text
#  is_mandatory             :boolean          default(FALSE)
#  is_enable_field_logic    :boolean          default(FALSE)
#  is_enable_range          :boolean          default(FALSE)
#  is_display_field         :boolean
#  custom_widgeted          :boolean          default(FALSE)
#  is_custom_aggregator     :boolean          default(FALSE)
#  is_criteria              :boolean          default(FALSE)
#  readonly_custom_widgeted :boolean          default(FALSE)
#

class Field < ActiveRecord::Base
  include Field::Base
  include Field::ElasticSearchConcern
  include Field::ValidationConcern
  include Field::ShpConcern

  include Field::TranslatableValue

  include HistoryConcern

  self.inheritance_column = :kind

  belongs_to :collection
  belongs_to :layer

  validates_presence_of :ord
  validates_inclusion_of :kind, :in => proc { kinds() }
  validates_presence_of :code
  validates_exclusion_of :code, :in => proc { reserved_codes() }
  validates_uniqueness_of :code, :scope => :collection_id
  validates_uniqueness_of :name, :scope => :collection_id

  serialize :config, MarshalZipSerializable
  serialize :metadata

  def self.reserved_codes
    ['lat', 'long', 'name', 'resmap-id', 'last updated']
  end

  before_save :set_collection_id_to_layer_id, :unless => :collection_id?
  def set_collection_id_to_layer_id
    self.collection_id = layer.collection_id if layer
  end

  before_save :save_config_as_hash_not_with_indifferent_access, :if => :config?
  def save_config_as_hash_not_with_indifferent_access
    self.config = config.to_hash

    self.config['options'].map!(&:to_hash) if self.config['options']
    sanitize_hierarchy_items self.config['hierarchy'] if self.config['hierarchy']
  end

  after_create :update_collection_mapping
  def update_collection_mapping
    collection.update_mapping
  end

  # inheritance_column added to json
  def serializable_hash(options = {})
    { "kind" => kind }.merge super
  end

  class << self
    def new_with_cast(*field_data, &b)
      hash = field_data.first
      kind = (field_data.first.is_a? Hash)? hash[:kind] || hash['kind'] || sti_name : sti_name
      klass = find_sti_class(kind)
      raise "Field is an abstract class and cannot be instanciated."  unless (klass < self || self == klass)
      hash.delete "kind" if hash
      hash.delete :kind if hash
      klass.new_without_cast(*field_data, &b)
    end
    alias_method_chain :new, :cast
  end

  def self.find_sti_class(kind)
    "Field::#{kind.classify}Field".constantize
  end

  def self.sti_name
    from_class_name_to_underscore(name)
  end

  def self.inherited(subclass)
    Layer.has_many "#{from_class_name_to_underscore(subclass.name)}_fields".to_sym, class_name: subclass.name
    Collection.has_many "#{from_class_name_to_underscore(subclass.name)}_fields".to_sym, class_name: subclass.name
    super
  end

  def self.from_class_name_to_underscore(name)
    underscore_kind = name.split('::').last.underscore
    match = underscore_kind.match(/(.*)_field/)
    if match
      match[1]
    else
      underscore_kind
    end
  end

  def assign_attributes(new_attributes, options = {})
    if (new_kind = (new_attributes["kind"] || new_attributes[:kind]))
      if new_kind == kind
        new_attributes.delete "kind"
        new_attributes.delete :kind
      else
        raise "Cannot change field's kind"
      end
    end
    super
  end

  def default_value_for_update
    nil
  end

  def history_concern_foreign_key
    'field_id'
  end

  def default_value_for_create(collection)
    nil
  end

  def value_type_description
    "#{kind} values"
  end

  def value_hint
    nil
  end

  def error_description_for_invalid_values(exception)
    "are not valid for the type #{kind}"
  end

  # Enables caching options and other info for a read-only usage
  # of this field, so that validations and such can be performed faster.
  def cache_for_read
  end

  def parse value
    value
  end

  def support_skip_logic?
    kind == "numeric" or kind == "select_one" or kind == "select_many" or kind == "yes_no"
  end

  def reinitial_config_from_original_collection collection
    if self.config && self.config["field_logics"] && self.config["field_logics"].length > 0
      self.config["field_logics"] = reinitial_skip_logic_from_original_collection(collection)
      self.save
    end

    if self.config && self.config["field_validations"] && self.config["field_validations"].length > 0
      self.config["field_validations"] = reinitial_custom_validation_from_original_collection(collection)
      self.save
    end

    if self.config && self.config["dependent_fields"] && self.config["dependent_fields"].length > 0
      self.config["dependent_fields"] = reinitial_dependent_field_calculation_from_original_collection(collection)
      self.save
    end

    if self.is_enable_dependancy_hierarchy && self.config && self.config["parent_hierarchy_field_id"]
      self.config["parent_hierarchy_field_id"] = reinitial_dependent_field_hierarchy_from_original_collection(collection)
      self.save
    end

    return self
  end

  def reinitial_skip_logic_from_original_collection collection
    self.config["field_logics"].each do |field_logic|
      next if !field_logic["field_id"] || field_logic["field_id"] == ""
      original_ref_field = collection.fields.find_by_id(field_logic["field_id"])
      target_ref_field = self.collection.fields.find_by_code(original_ref_field.code) if original_ref_field
      field_logic["field_id"] = "#{target_ref_field.id}" if target_ref_field
    end
    return self.config["field_logics"]
  end

  def reinitial_custom_validation_from_original_collection collection
    self.config["field_validations"].each do |key, item|
      next if !item["field_id"][0] || item["field_id"][0] == ""
      original_ref_field = collection.fields.find_by_id(item["field_id"][0]) if item["field_id"].length > 0
      target_ref_field = self.collection.fields.find_by_code(original_ref_field.code) if original_ref_field
      item["field_id"] = ["#{target_ref_field.id}"] if target_ref_field
    end
    return self.config["field_validations"]
  end

  def reinitial_dependent_field_calculation_from_original_collection collection
    self.config["dependent_fields"].each do |key, item|
      next if !item["id"] || item["id"] == ""
      original_ref_field = collection.fields.find_by_id(item["id"])
      target_ref_field = self.collection.fields.find_by_code(original_ref_field.code) if original_ref_field
      item["id"] = "#{target_ref_field.id}" if target_ref_field
    end
    return self.config["dependent_fields"]
  end

  def reinitial_dependent_field_hierarchy_from_original_collection collection
    original_ref_field = collection.fields.find_by_id(self.config["parent_hierarchy_field_id"])
    target_ref_field = self.collection.fields.find_by_code(original_ref_field.code) if original_ref_field
    self.config["parent_hierarchy_field_id"] = "#{target_ref_field.id}" if target_ref_field

    return self.config["parent_hierarchy_field_id"]
  end

  def migrate_skip_logic
    if is_enable_field_logic
      config["field_logics"] = config["field_logics"] || []
      id_field_logic = 0;
      config["field_logics"].each do |field_logic|
        if field_logic["field_id"] and field_logic["field_id"] != "null" and field_logic["field_id"] != ["0", "null"]
          from_id = [ id.to_i, field_logic["field_id"].to_i].min
          to_id = [ id.to_i, field_logic["field_id"].to_i].max
          start = false
          collection.layers.each do |l|
            fs = l.fields
            fs.each do |f|
              if f.id == from_id
                start = true
              elsif f.id.to_i == to_id
                start = false
                break;
              elsif start
                f.is_enable_field_logic = true
                f.config = f.config || {}
                f.config["field_logics"] = f.config["field_logics"] || []
                f.config["field_logics_tmp"] = f.config["field_logics_tmp"] || []
                if kind == "select_many"
                  list_codes = []
                  if field_logic["condition_type"] == "all"
                    field_logic["selected_options"].each do |opt, index|
                      config["options"].each do |c|
                        if opt["value"] == c["id"]
                          list_codes.push(c["code"])
                        end
                      end
                    end

                    f.config["field_logics_tmp"].push({"id" => id_field_logic, "field_id" => [id], "condition_type" => "=", "value" => list_codes.join(",")})
                  elsif field_logic["condition_type"] == "any"
                    field_logic["selected_options"].each do |opt, index|
                      config["options"].each do |c|
                        if opt["value"] == c["id"]
                          f.config["field_logics_tmp"].push({"id" => id_field_logic, "field_id" => [id], "condition_type" => "=" , "value" => c["code"].to_s})
                        end
                      end
                    end
                  end
                elsif kind == "select_one"
                  config["options"].each do |c|
                    if field_logic["value"] == c["id"]
                      f.config["field_logics_tmp"].push({"id" => id_field_logic, "field_id" => [id], "condition_type" => "=", "value" => c["code"]})
                    end
                  end
                elsif kind == "yes_no"
                  f.config["field_logics_tmp"].push({"id" => id_field_logic, "field_id" => [id], "condition_type" => "=" , "value" => field_logic["value"]})
                else
                  f.config["field_logics_tmp"].push({"id" => id_field_logic, "field_id" => [id], "condition_type" => field_logic["condition_type"] , "value" => field_logic["value"]})
                end
                f.save!
              end
            end
          end
        end
        id_field_logic = id_field_logic + 1
      end
      save!
    end
  end

  def self.migrate_code
    Field.transaction do
      Field.find_each(batch_size: 100) do |field|
        code = field.code
        valid_code = false
        new_code = code
        if(!code.ascii_only?)
          new_code = (0...16).map { ('A'..'Z').to_a[rand(26)] }.join
          field.migrate_related_code(new_code)
          field.code = new_code
          field.save
          valid_code = true
        end
        if(valid_code == false)
          new_code = code.gsub(/[^0-9A-Za-z_]/) do |template|
            valid_code = true
            template = '_'
          end
          if(valid_code == true)
            field.migrate_related_code(new_code)
            field.code = new_code
            field.save
          end
        end
      end
    end
  end

  # calculation and alert use field code as the template
  def migrate_related_code(new_code)
    migrate_calculation_code(new_code)
    migrate_theshold_message_notification(new_code)
  end

  private

  def migrate_calculation_code new_code
    self.collection.fields.where(kind: 'calculation').each do |field|
      if field.config["dependent_fields"] && field.config["dependent_fields"].length > 0
        code_calculation = field.config['code_calculation']
        field.config["dependent_fields"].each do |key, dependent_field|
          ref_dependent_field = self.collection.fields.find(dependent_field['id'])
          if ref_dependent_field
            code_calculation = code_calculation.gsub(/\{#{dependent_field['code']}}/, "{#{ref_dependent_field.code}}")
            field.config['dependent_fields'][key]['code'] = ref_dependent_field.code
          end
        end
        field.config['code_calculation'] = code_calculation
        field.save
      end
    end
  end

  def migrate_theshold_message_notification new_code
    self.collection.thresholds.each do |threshold|
      if threshold.message_notification
        threshold.message_notification = threshold.message_notification.gsub(/\[#{self.code}]/, "[#{new_code}]")
        threshold.save
      end
    end
  end

  def add_option_to_options(options, option)
    if option["parent_id"] and option["level"]
      options << { id: option['id'], name: option['name'], parent_id: option['parent_id'], level: option['level']}
    else
      options << { id: option['id'], name: option['name']}
    end
    if option['sub']
      option['sub'].each do |sub_option|
        add_option_to_options(options, sub_option)
      end
    end
  end

  def sanitize_hierarchy_items(items)
    items.map! &:to_hash
    items.each do |item|
      sanitize_hierarchy_items item['sub'] if item['sub']
    end
  end

end
