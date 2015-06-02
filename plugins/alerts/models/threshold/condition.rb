class Threshold::Condition
  include Threshold::ComparisonConcern

  attr_accessor :operator, :value

  def initialize(hash, properties)
    @operator = hash[:op]
    if hash[:type] == "percentage"
      @value = hash[:value] * (properties[hash[:compare_field]] || 0) / 100
    else
      @value = hash[:value]
    end
  end

  def evaluate(field, value)
    if field[:kind] == "hierarchy"
      @value = field.descendants_of_in_hierarchy(value, false)
    end
    p '@value : ', @value
    p 'value : ', value
    return false if value.nil? || @value.nil?
    send @operator, value, @value
  end
end
