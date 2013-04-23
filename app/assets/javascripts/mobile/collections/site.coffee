#= require module

onMobileCollections ->
  class @Site extends Module
    constructor: (collection, data) ->
      @id = data?.id
      @collection = collection
      @name = ko.observable data?.name
      @idWithPrefix = ko.observable data?.id_with_prefix
      @properties = ko.observable data?.properties
      
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @editingName = ko.observable(false)
      @editingLocation = ko.observable(false)
      @alert = ko.observable data?.alert
      @locationText = ko.computed
        read: =>
          if @hasLocation()
            (Math.round(@lat() * 1000000) / 1000000) + ', ' + (Math.round(@lng() * 1000000) / 1000000)
          else
            ''
        write: (value) => @locationTextTemp = value
        owner: @
      @locationTextTemp = @locationText()
      @valid = ko.computed => @hasName()
      @highlightedName = ko.computed => window.model.highlightSearch(@name())
      @inEditMode = ko.observable(false)

    hasLocation: => @position() != null

    hasName: => @.trim(@name()).length > 0

