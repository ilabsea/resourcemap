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

class Field::NumericField < Field

  def value_type_description
    "numeric values"
  end

  def value_hint
    "Values must be integers."
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
    standadrize(value)
	end

  def standadrize(value)
    if allow_decimals?
      value.to_f
    else
      value.to_i
    end
  end

  def decode(value)
    if allow_decimals?
      raise allows_decimals_message unless value.real?
      Float(value)
    else
      raise not_allow_decimals_message unless value.integer?
      Integer(value)
    end
  end

  def valid_value?(value, site = nil)
    if allow_decimals?
      raise allows_decimals_message unless value.real?
    else
      raise not_allow_decimals_message if !value.integer? && value.real?
      raise invalid_field_message unless value.integer?
    end
    if config and config['range']
      validate_range(value)
    end
    if config and config['field_validations']
      validate_custom_validation(value, site)
    end
    true
  end

  def validate_range(value)
    if config['range']['minimum'] && config['range']['maximum'] && config['range']['minimum'] <= config['range']['maximum']
      unless value.to_f >= config['range']['minimum'] && value.to_f <= config['range']['maximum']
        raise "Invalid value, value must be in the range of (#{config['range']['minimum']}-#{config['range']['maximum']})"
      end
    end

    if config['range']['minimum']
      raise "Invalid value, value must be greater than or equal #{config['range']['minimum']}" unless value.to_f >= config['range']['minimum']
    end

    if config['range']['maximum']
      raise "Invalid value, value must be less than or equal #{config['range']['maximum']}" unless value.to_f <= config['range']['maximum']
    end
  end

  def validate_custom_validation(value, site)
    config['field_validations'].each do |key, cond|
      compare_value = site.properties[cond["field_id"][0]]
      reference_field = Field.where("id=?", cond["field_id"][0])[0]
      raise "Field set custom validate that reference to missing field." unless reference_field
      compare_field_name = reference_field.name
      unless compare(value.to_f, compare_value.to_f, cond["condition_type"])
        raise "Invalid value, value must be #{operator_to_word(cond["condition_type"])} field #{compare_field_name}"
      end
    end
  end

  def compare(value1, value2, operator)
    case operator
    when '='
      value1 == value2
    when ">"
      value1 > value2
    when ">="
      value1 >= value2
    when "<"
      value1 < value2
    when "<="
      value1 <= value2
    else
      false
    end

  end

  def to_dbf_field
    length, decimal = allow_decimals? ? [8, 1] : [4, 0]
    Collection.dbf_field_for self.code, type: 'N', length: length, decimal: decimal
  end

  private

  def invalid_field_message()
    "Invalid numeric value in field #{code}"
  end

  def allows_decimals_message()
    "#{invalid_field_message}. This numeric field is configured to allow decimal values."
  end

  def not_allow_decimals_message()
    "#{invalid_field_message}. This numeric field is configured not to allow decimal values."
  end

  def invalid_range()
    "Invalid range"
  end

  def operator_to_word opt
    case opt
    when '<'
      "less than"
    when '<='
      "less than or equal to"
    when '=='
      "equal to"
    when '>'
      "greater than"
    when '>='
      "greater than or equal to"
    when '!='
      "not equal to"
    end
  end
end
