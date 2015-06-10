require 'net/http'

namespace :threshold do
  desc "add the condition field kind to threhold"
  task :migrate => :environment do
    Threshold.add_condition_field_kind
  end
end