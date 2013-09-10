class ExecVisitor < Visitor
  MSG = {
    :query_not_match => "No result. Your query did not match.",
    :update_successfully => "Data has been successfull updated.",
    :can_not_update => "You have no access right to update. Please contact the collection's owner for more information.", :can_not_query => "You have no access right to view. Please contact the collection's owner for more information.", :can_not_use_gateway => "You cannot use this channel for viewing or updating this collection. Please contact the collection's owner for more information.",
    :can_not_add => "Invalid command.",
    :added_successfully => "Site has been successfull added.",
    :name_is_required => "Site name is required.",
    :can_not_find_site => "Can't find site with ID="
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
      raise MSG[:can_not_update]      unless can_update?(node.property_list, node.sender, site)
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
      collection = Collection.find node.collection_id.value
    end
    
    if collection
      key_value_properties = node_to_properties(node.property_list)
      site = node_to_site key_value_properties
      if not site.keys.include?('name')
        return MSG[:name_is_required]
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
      if collection.sites.create site
        MSG[:added_successfully] 
      else
        MSG[:can_not_add]
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
      field =Field.where("code=? and collection_id=?", p.values[0], site.collection_id).first
      site.properties[field.es_code] = p.values[1]
    end
    site.save!
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

  def node_to_site_properties(key_value_properties, collection_id)
    properties = {}
    key_value_properties.each { |property|
      code = property[:code]
      if code != 'name' and code != 'lat' and code != 'lng'
        id = get_field_id(code,collection_id)
        if id
          properties[id.to_s] =  property[:value]
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
end
