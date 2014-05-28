class Threshold < ActiveRecord::Base
  belongs_to :collection

  validates :collection, :presence => true
  validates :ord, :presence => true
  validates :color, :presence => true

  serialize :conditions, Array
  serialize :phone_notification
  serialize :email_notification
  serialize :sites, Array

  before_save :strongly_type_conditions
  def strongly_type_conditions
    fields = collection.fields.index_by(&:es_code)
    self.conditions.each_with_index do |hash, i|
      field = fields[hash[:field]]
      self.conditions[i][:value] = field.strongly_type(hash[:value]) if field
    end
  end

  def test(properties)
    fields = collection.fields.index_by &:es_code
    throw :threshold, self if conditions.send(is_all_condition ? :all? : :any?) do |hash|
      field = fields[hash[:field]]
      value = properties[hash[:field]] || field.strongly_type(value)

      true if condition(hash, properties).evaluate(value)
    end
  end

  def condition(hash, properties)
    Threshold::Condition.new hash, properties
  end
end
