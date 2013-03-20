class ExecVisitor < Visitor
  MSG = {
    :query_not_match => "No result. Your query did not match.",
    :update_successfully => "Data has been successfull updated.",
    :can_not_update => "You have no access right to update. Please contact the layer's owner for more information.", :can_not_query => "You have no access right to view. Please contact the layer's owner for more information.", :can_not_use_gateway => "You cannot use this channel for viewing or updating this layer. Please contact the layer's owner for more information.",
    :can_not_add => "Invalid command.",
    :added_successfully => "Site has been successfull added."
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
      raise "Can't find site with ID=#{id}" if site.nil?
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
      site = node_to_site node.property_list
      site["properties"] = node_to_site_properties node.property_list,collection.id
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

  private
  
  def update(site, node, sender)
    properties = node_to_properties(node)
		site.update_properties site, sender, properties
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
    Field.where("code=? and collection_id=?",field_code, collection_id).first.id
  end

  def node_to_site_properties(node, collection_id)
    properties = {}
		until node and node.kind_of? AssignmentExpressionNode
      code = node.assignment_expression.to_options[:code]
      if code != 'name' and code != 'lat' and code != 'lng'
        id = get_field_id(code,collection_id)
        properties[id.to_s] =  node.assignment_expression.to_options[:value] if id
      end
      node = node.next
    end
    properties
  end
  
  def node_to_site(node)
    site = {}
    until node and node.kind_of? AssignmentExpressionNode
      code = node.assignment_expression.to_options[:code]
      site[code] = node.assignment_expression.to_options[:value] if code == 'name' or code == 'lat' or code == 'lng'
      node = node.next
    end
    site
  end
end
