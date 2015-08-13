module Field::TireConcern
  extend ActiveSupport::Concern

  def index_mapping
    case
    when kind == 'yes_no'
      { type: :boolean }
    when storeed_as_long?
      { type: :long }
    when stoted_as_double?
      { type: :double }
    when stored_as_date?
      { type: :date }
    else
      { type: :string, index: :not_analyzed }
    end
  end

  # Returns the code to store this field in Elastic Search
  def es_code
    id.to_s
  end

  module ClassMethods
    def where_es_code_is(es_code)
      where(:id => es_code.to_i).first
    end
  end
end
