module Collection::CsvConcern
  extend ActiveSupport::Concern
  # include Rails.application.routes.url_helpers
  def csv_template
    CSV.generate do |csv|
      csv << sample_csv_header
      csv << [1, "Site 1", 1.234, 5.678]
      csv << [2, "Site 2", 3.456, 4.567]
    end
  end


  def location_csv(locations)
    CSV.generate do |csv|
      locations.each do |location|
        csv << [location["code"], location["name"], location["latitude"], location["longitude"]]
        
  def to_csv(elastic_search_api_results = new_search.unlimited.api_results, current_user)

    fields = self.fields.all
    hierarchy_fields = {}
    CSV.generate do |csv|
      header = ['resmap-id', 'name', 'lat', 'long']
      fields.each { |field| header << field.code }

      header << 'last updated'
      csv << header

      elastic_search_api_results.each do |result|
        source = result['_source']

        row = [source['id'], source['name'], source['location'].try(:[], 'lat'), source['location'].try(:[], 'lon')]
        fields.each do |field|
          if field.kind == 'yes_no'
            row << (Field.yes?(source['properties'][field.code]) ? 'yes' : 'no')
          elsif field.kind == 'photo'
            row << "#{Settings.host}/photo_field/#{source['properties'][field.code]}"
          else
            row << Array(source['properties'][field.code]).join(", ")
          end
        end
        if current_user
          updated_at = Site.iso_string_to_rfc822_with_timezone(source['updated_at'], current_user.time_zone)
        else
          updated_at = Site.iso_string_to_rfc822(source['updated_at'])
        end
        # row << Site.iso_string_to_rfc822(source['updated_at'])
        row << updated_at
        csv << row
      end
    end
  end

  def sample_csv(user = nil)
    fields = self.fields.all

    CSV.generate do |csv|
      header = ['name', 'lat', 'long']
      writable_fields = writable_fields_for(user)
      writable_fields.each { |field|
        field_header = field.csv_header
        if field_header.kind_of?(Array)
          header = header + field_header
        else
          header << field.csv_header
        end
      }
      csv << header
      row = ['Paris', 48.86, 2.35]
      writable_fields.each do |field|
        if field.csv_header.kind_of?(Array)
          field.csv_header.each do |header|
            row << Array(field.sample_value user).join(", ")
          end
        else
          row << Array(field.sample_value user).join(", ")
        end
      end
      csv << row
    end
  end

  def sample_members_csv(user = nil)
    fields = self.fields.all

    CSV.generate do |csv|
      header = ['email','None','Read','Update','Admin','View data submitted by other user','Edit data submitted by other user']
      csv << header
      row = ['sample_user@email.com',0,0,0,1,1,1]
      csv << row
    end
  end

  def import_csv(user, string_or_io)
    Collection.transaction do
      csv = CSV.new string_or_io, return_headers: false

      new_sites = []
      csv.each do |row|
        next unless row[0].present? && row[0] != 'resmap-id'

        site = sites.new name: row[1].strip
        site.mute_activities = true
        site.lat = row[2].strip if row[2].present?
        site.lng = row[3].strip if row[3].present?
        new_sites << site
      end

      new_sites.each &:save!

      Activity.create! item_type: 'collection', action: 'csv_imported', collection_id: id, user_id: user.id, 'data' => {'sites' => new_sites.length}
    end
  end

  def decode_hierarchy_csv(string)

    csv = CSV.parse(string)

    # First read all items into a hash
    # And validate it's content
    items = validate_format_hierarchy(csv)

    items.each do |order, item|
      if item[:parent].present? && !item[:error].present?
        parent_candidate = items[item[:parent].to_i]
        if parent_candidate
          parent_candidate[:sub] ||= []
          parent_candidate[:sub] << item
        end
      end
    end


    # Remove those that have parents, and at the same time delete their parent key
    items = items.reject do |order, item|
      if item[:parent] && !item[:error].present?
        item.delete :parent
        true
      else
        false
      end
    end


    items.values

    rescue Exception => ex
      return [{error: ex.message}]

  end

  def decode_location_csv(string)
    csv = CSV.parse(string)

    items = validate_format_location(csv)

    locations = []
    items.each do |item|
      locations.push item[1]
    end
    
    locations
    
    rescue Exception => ex
      return [{error: ex.message}]
  end

  def validate_format_location(csv)
    i = 0
    items = {}
    csv.each do |row|
      item = {}
      if row[0] == 'Code'
        next
      else
        i = i+1
        item[:order] = i

        if row.length != 4
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else

          #Check unique name
          name = row[1].strip
          if items.any?{|item| item.second[:name] == name}
            item[:error] = "Invalid name."
            item[:error_description] = "location name should be unique"
            error = true
          end
          
          #Check unique id
          code = row[0].strip
          if items.any?{|item| item.second[:code] == code}
            item[:error] = "Invalid code."
            item[:error_description] = "location code should be unique"
            error = true
          end

          if !error
            item[:code] = code
            item[:name] = name
            item[:latitude] = row[2].strip
            item[:longitude] = row[3].strip
          end
        end

        items[item[:order]] = item
      end
    end
    items
  end

  def validate_format_location(csv)
    i = 0
    items = {}
    csv.each do |row|
      item = {}
      if row[0] == 'Code'
        next
      else
        i = i+1
        item[:order] = i

        if row.length != 4
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else

          #Check unique name
          name = row[1].strip

          #Check unique id
          code = row[0].strip
          if items.any?{|item| item.second[:code] == code}
            item[:error] = "Invalid code."
            item[:error_description] = "location code should be unique"
            error = true
          end

          if !error
            item[:code] = code
            item[:name] = name
            item[:latitude] = row[2].strip
            item[:longitude] = row[3].strip
          end
        end

        items[item[:order]] = item
      end
    end
    items
  end

  def validate_format_hierarchy(csv)
    i = 0
    items = {}
    hierarchy_ids = csv.map{|item| "#{item[0]}"}

    csv.each do |row|
      item = {}
      if row[0] == 'ID'
        next
      else
        i = i+1
        item[:order] = i

        if row.length != 3
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else
          #Check unique id
          id = row[0].strip
          if hierarchy_ids.count(id) > 1
            item[:error] = "Invalid id."
            item[:error_description] = "Hierarchy id should be unique"
            error = true
          end

          #Check parent id exists
          if row[1].present?
            parent_id = row[1].strip
            if !(hierarchy_ids.include? parent_id)
              item[:error] = "Invalid parent value."
              item[:error_description] = "ParentID should match one of the Hierarchy ids"
              error = true
            end
          end

          if !error
            item[:id] = id
            item[:parent] = parent_id if parent_id
            item[:name] = row[2].strip
          end
        end

        items[item[:id].to_i] = item
      end
    end
    items
  end

  private

  def sample_csv_header
    ["Site ID", "Name", "Lat", "Lng"]
  end

  def fields_for_csv
    fields = []
    self.layers.each {|layer| fields = fields + layer.fields_for_csv}
    return fields
  end


  def csv_header fields
    CSV.generate do |csv|
      header = ['resmap-id', 'name', 'lat', 'long']
      fields.each do |field|
        field_header = field.csv_header
        if field_header.kind_of?(Array)
          header = header + field_header
        else
          header << field.csv_header
        end
      end
      header << 'start entry date'
      header << 'end entry date'
      header << 'last updated'
      csv << header
    end
  end


  def csv_body sites, fields
    csv = []
    sites.each do |result|
      source = result['_source']

      row = [source['id'], source['name'], source['location'].try(:[], 'lat'), source['location'].try(:[], 'lon')]
      fields.each do |field|
        if field.kind == 'yes_no'
          row << (Field.yes?(source['properties'][field.code]) ? 'yes' : 'no')
        elsif field.kind == 'photo'
          if source['properties'][field.code].present?
            row << "http://#{Settings.host}/view_photo?uuid=#{source['uuid']}&file_name=#{source['properties'][field.code]}"
          else
            row << ""
          end
        elsif field.kind == "select_one"
          row << field.value_for_csv(source['properties'][field.code])
        elsif field.kind == 'select_many'
          field.config["options"].each do |option|
            if source['properties'][field.code] and source['properties'][field.code].include? option["id"]
              row << "Yes"
            else
              row << "No"
            end
          end
        elsif field.kind == "hierarchy"
          if field.is_enable_dependancy_hierarchy
            row << field.value_for_csv(source['properties'][field.code])
          else
            row = row + field.value_for_csv(source['properties'][field.code])
          end
        else
          row << Array(source['properties'][field.code]).join(", ")
        end
      end

      updated_at = Site.parse_time(source['updated_at']).strftime("%d/%m/%Y %H:%M:%S")
      start_entry_date = Site.parse_time(source['start_entry_date']).strftime("%d/%m/%Y %H:%M:%S") if source['start_entry_date'].present?
      end_entry_date = Site.parse_time(source['end_entry_date']).strftime("%d/%m/%Y %H:%M:%S") if source['end_entry_date'].present?

      row << start_entry_date
      row << end_entry_date
      row << updated_at
      csv << row
    end
    return csv
  end

end
