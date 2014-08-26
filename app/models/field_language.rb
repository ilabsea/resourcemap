class FieldLanguage < ActiveRecord::Base
	serialize :config, Hash
end