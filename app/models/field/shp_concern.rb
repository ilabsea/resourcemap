require 'dbf'

module Field::ShpConcern
  extend ActiveSupport::Concern

  def to_dbf_field
    Collection.dbf_field_for self.code, type: 'C', length: 100
  end
end