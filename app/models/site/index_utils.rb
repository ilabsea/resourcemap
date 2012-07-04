module Site::IndexUtils
  extend self

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  def store(site, site_id, index, options = {})
    hash = {
      id: site_id,
      name: site.name,
      type: :site,
      properties: site.properties,
      created_at: site.created_at.strftime(DateFormat),
      updated_at: site.updated_at.strftime(DateFormat),
    }

    hash[:location] = {lat: site.lat.to_f, lon: site.lng.to_f} if site.lat? && site.lng?
    alert = site.collection.thresholds_test site.properties, site.id unless site.is_a? SiteHistory
    
    if(alert != nil)
      hash[:alert] = true
      hash[:icon] = alert.icon
      users = User.find alert.phone_notification
      Resque.enqueue SmsQueue, users, alert.message_notification
      Resque.enqueue EmailQueue, alert_
    else
      hash[:alert] = false
      hash[:icon] = nil
    end
    result = index.store hash
    
    if result['error']
      raise "Can't store site in index: #{result['error']}"
    end
    
    index.refresh unless options[:refresh] == false
  end

  def site_mapping(fields)
    {
      properties: {
        name: { type: :string, index: :not_analyzed },
        location: { type: :geo_point },
        created_at: { type: :date, format: :basic_date_time },
        updated_at: { type: :date, format: :basic_date_time },
        properties: { properties: fields_mapping(fields) },
      }
    }
  end

  def fields_mapping(fields)
    fields.each_with_object({}) { |field, hash| hash[field.es_code] = field.index_mapping }
  end
end
