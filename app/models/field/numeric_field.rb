class Field::NumericField < Field

  def value_type_description
    "numeric values"
  end

  def value_hint
    "Values must be integers."
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
    valid_value?(value)
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
    true
  end

  def validate_range(value)
    if config['range']['minimum'] && config['range']['maximum'] && config['range']['minimum'] <= config['range']['maximum']
      unless value.to_i >= config['range']['minimum'] && value.to_i <= config['range']['maximum']
        raise "Invalid value, value must in the range of (#{config['range']['minimum']}-#{config['range']['maximum']})"
      end
    end
    
    if config['range']['minimum']
      raise "Invalid value, value must greater than or equal #{config['range']['minimum']}" unless value.to_i >= config['range']['minimum']
    end

    if config['range']['maximum']
      raise "Invalid value, value must less than or equal #{config['range']['maximum']}" unless value.to_i <= config['range']['maximum']
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
end
