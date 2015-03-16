class Threshold < ActiveRecord::Base
  belongs_to :collection

  validates :collection, :presence => true
  validates :ord, :presence => true
  validates :color, :presence => true

  serialize :conditions, Array
  serialize :phone_notification
  serialize :email_notification
  serialize :sites, Array

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
      if field
        value = properties[hash[:field]] || field.strongly_type(value)

        true if condition(hash, properties).evaluate(value)
      end
    end
  end

  def condition(hash, properties)
    Threshold::Condition.new hash, properties
  end

  def self.get_thresholds_by_user(user)
    Threshold.where(:collection_id => Collection.joins(:memberships).where("memberships.user_id = :user_id", :user_id => user.id))   
  end

  def self.get_thresholds_with_public_collection
    Threshold.where(:collection_id => Collection.public_collections)
  end

  def self.add_condition_field_kind
    Threshold.transaction do
      Threshold.find_each(batch_size: 100) do |threshold|
        threshold.conditions.each do |condition|
          field = Field.find(condition[:field])
          condition[:kind] = field.kind if field
        end
        threshold.save
      end
    end    
  end

end
