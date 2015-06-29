class Field::YesNoField < Field

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    check_presence_of_value(value)
    Field.yes?(value)
  end

  def decode(value)
    Field.yes?(value)
  end

  def decode_from_ui value
    decode value
  end

  def default_value_for_update
    if config && Field.yes?(config['auto_reset'])
      false
    else
      nil
    end
  end

end
