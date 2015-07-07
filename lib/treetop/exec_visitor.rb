class ExecVisitor < Visitor
  MSG = {
    :query_not_match => "No result. Your query did not match.",
    :update_successfully => "Data has been successfully updated.",
    :no_rights_not_update => "You have no access rights to update. Please contact the collection's owner for more information.", 
    :can_not_query => "You have no access rights to view. Please contact the collection's owner for more information.", 
    :can_not_use_gateway => "You cannot use this channel for viewing or updating this collection. Please contact the collection's owner for more information.",
    :can_not_update => "Can not update site ",
    :can_not_add => "Can not create site ",
    :added_successfully => "Site has been successfully added.",
    :name_is_required => "Site name is required.",
    :can_not_find_site => "Can't find site with ID=",
    :can_not_add_site => "You don't have permission to add site."
  }

  attr_accessor :context
  def initialize(context={})
    self.context = context
  end
   
  def visit_query_command(node)
    if collection = Collection.find_by_id(node.collection_id.value)
      #raise MSG[:can_not_use_gateway] unless can_use_gateway?(collection)
      raise MSG[:can_not_query]       unless can_view?(node.conditional_expression.to_options, node.sender, collection)
      if reply = collection.query_sites(node.conditional_expression.to_options)
        reply.empty? ? MSG[:query_not_match] : reply
      end
    end
  end

  def visit_update_command(node)
    id = node.resource_id.text_value
    if site = Site.find_by_id_with_prefix(id)
      #raise MSG[:can_not_use_gateway] unless can_use_gateway?(site.collection)
      raise MSG[:no_rights_not_update]      unless can_update?(node.property_list, node.sender, site)
      update site, node.property_list, node.sender 
      MSG[:update_successfully]
    else
      raise MSG[:can_not_find_site] + id if site.nil?
    end
  end

  def visit_add_command(node)
    if node.collection_id.text_value.empty?
      collections = node.sender.collections
      if collections.length != 1
        return "Collection id is needed in your message."
      else
        collection = collections.first
      end
    else
      return MSG[:can_not_add_site] if node.sender.nil? or not node.sender.can_add?(node.collection_id.value)
      collection = Collection.find node.collection_id.value
    end
    
    if collection
      key_value_properties = node_to_properties(node.property_list)
      site = node_to_site key_value_properties
      if collection.is_visible_name == true && (not site.keys.include?('name'))
        return MSG[:name_is_required]
      end

      properties_none_write = can_write_properties(key_value_properties, node.sender, collection)
      
      if properties_none_write.length > 1
        return 'Field codes: ' + properties_none_write.join(',') + ' do not have permission to add.'
      elsif properties_none_write.length == 1
        return 'Field code: ' + properties_none_write.join(',') + ' does not have permission to add.'
      end

      properties = node_to_site_properties key_value_properties,collection.id
      if properties["not_exist"]
        if properties["not_exist"].length > 1
          return 'Field codes: ' + properties["not_exist"].join(',') + ' are not exist.'
        else
          return 'Field code: ' + properties["not_exist"].join(',') + ' is not exist.'
        end
      end
      site["properties"] = node_to_site_properties key_value_properties,collection.id
      site["user"] = node.sender
      new_site = collection.sites.new site
      if new_site.valid?
        new_site.save!
        MSG[:added_successfully] 
      else
        errors = []
        new_site.errors.messages[:properties].each do |e|
          e.each do |key, value|
            errors.push "- " + value
          end
        end
        MSG[:can_not_add] + "\n" + errors.join("\n")
      end
    else
      MSG[:can_not_add]
    end
  end

  def can_use_gateway?(colleciton)
    gateway = Gateway.find_by_nuntium_name(self.context[:channel])
    gateway.nil? || gateway.allows_layer?(layer)
  end

  def can_view?(option, sender, collection)
    sender && sender.can_view?(collection, option[:code])
  end

  def can_update?(node, sender, site)
    properties = node_to_properties node
    sender && sender.can_update?(site, properties)
  end

  def update(site, node, sender)
    properties = node_to_properties(node)
    update_properties site, sender, properties
  end

  def update_properties(site, user, props)
    site.user = user
    props.each do |p|
      code = p[:code]
      if code != "name"
        field =Field.where("code=? and collection_id=?", p.values[0], site.collection_id).first
        site.properties[field.es_code] = to_supported_value(field, p.values[1])
      else
        site[code] = p.values[1]
      end
    end
    if site.valid?
      site.save!
    else
      errors = []
      site.errors.messages[:properties].each do |e|
        e.each do |key, value|
          errors.push "- " + value
        end
      end
      raise  MSG[:can_not_update] + "\n" + errors.join("\n")
    end
  end

  def node_to_properties(node)
    properties = []
		until node and node.kind_of? AssignmentExpressionNode
      properties << node.assignment_expression.to_options
      node = node.next
    end
    properties << node.to_options
  end

  def get_field_id(field_code, collection_id)
    field = Field.where("code=? and collection_id=?",field_code, collection_id).first
    if field
      field.id
    else
      nil
    end
  end

  def can_write_properties(key_value_properties, sender, collection)
    properties_non_write = []
    key_value_properties.each { |property|
      code = property[:code]
      if code != 'name' and code != 'lat' and code != 'lng'
        can_write = sender.can_write?(collection, code)
        if !can_write
          properties_non_write.push code
        end
      end
    }
    properties_non_write
  end

  def node_to_site_properties(key_value_properties, collection_id)
    properties = {}
    key_value_properties.each { |property|
      code = property[:code]
      if code != 'name' and code != 'lat' and code != 'lng'
        id = get_field_id(code,collection_id)
        if id
          field =Field.find_by_id id
          properties[id.to_s] = to_supported_value(field, property[:value])
        else
          properties['not_exist'] = [] if properties['not_exist'].nil?
          properties['not_exist'].push code
        end
      end
    }
    properties
  end
  
  def node_to_site(key_value_properties)
    site = {}
    key_value_properties.each { |property|
      code = property[:code]
      site[code] = property[:value] if code == 'name' or code == 'lat' or code == 'lng'
    }
    site
  end

  def to_supported_value(field, value)
    case field.kind
    when "yes_no"
      return not(["n", "N", "no", "NO", "No", "nO",  "0"].include? value)
    when "select_one"
      field.config["options"].each do |op|
        return op["id"] if (op["code"] == value || op["label"] == value)
      end
    when "select_many"
      many_value = value.split('&')
      result = []
      many_value.each do |v|
        field.config["options"].each do |op|
          if (op["code"] == v || op["label"] == v)
            result.push(op["id"])
          end
        end
      end
      if result.length > 0
        return result
      else
        nil
      end
    else
      return value
    end
  end
end
