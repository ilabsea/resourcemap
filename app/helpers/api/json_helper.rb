module Api::JsonHelper
  def collection_json(collection, results)
    obj = {}
    obj[:id] = collection.id
    obj[:name] = collection.name
    obj[:is_visible_location] = collection.is_visible_location
    obj[:is_visible_name] = collection.is_visible_name
    obj[:previousPage] = url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
    obj[:nextPage] = url_for(params.merge page: results.next_page, only_path: false) if results.next_page
    obj[:count] = results.total
    obj[:totalPages] = results.total_pages
    obj[:sites] = results.map {|result| site_item_json result}
    obj
  end

  def site_item_json(result)
    source = result['_source']

    obj = {}
    obj[:id] = source['id']
    obj[:name] = source['name']
    obj[:createdAt] = Site.parse_time(source['created_at'])
    obj[:updatedAt] = Site.parse_time(source['updated_at'])

    if source['location']
      obj[:lat] = source['location']['lat']
      obj[:long] = source['location']['lon']
    end

    source['properties'].each do |key, property|
      field = Field.find_by_code(key)
      if field.kind == 'photo'
        source['properties'][key] = "#{Settings.host}/photo_field/#{property}"
        break
      end
    end
    
    obj[:properties] = source['properties']

    obj
  end
end
