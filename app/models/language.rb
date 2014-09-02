class Language < ActiveRecord::Base
	def load_fields_translation! fields
    fields.map! do |field|
      field.tap do
        translation = FieldLanguage.find_by_language_id_and_field_id self.id, field.id
        if translation
          field.name = translation.name
          field.config = translation.config
        end
      end
    end
  end
end