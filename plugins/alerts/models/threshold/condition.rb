class Threshold::Condition
  include Threshold::ComparisonConcern

  attr_accessor :operator, :value

  def initialize(hash, properties)
    @operator = hash[:op]
    if hash[:type] == "percentage"
      @value = hash[:value] * (properties[hash[:compare_field]] || 0) / 100
    else
      if (hash[:value].class == FalseClass or hash[:value].class == TrueClass or hash[:value].class == Fixnum)
        @value = hash[:value]
      elsif hash[:value].class == Float
        @value = hash[:value].to_f
      elsif hash[:value].class == String
        # if hash[:value].is_float?
        #   @value = hash[:value].to_f
        # elsif hash[:value].is_integer?
        #   @value = hash[:value].to_i
        # else
          @value = hash[:value]
        # end
      end
    end
  end

  def evaluate(field, value)
    if field[:kind] == "hierarchy" && value != nil && @value != nil
      @value = field.descendants_of_in_hierarchy(@value, false)
    end

    return false if value.nil? || @value.nil?
    send @operator, value, @value
  end
end
