class ShareNationalChannel < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection
  belongs_to :channel

end