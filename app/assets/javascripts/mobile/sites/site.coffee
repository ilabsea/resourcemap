onMobileSites ->
  class @Site
    constructor: (data) ->
      @selected = ko.observable()
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @idWithPrefix = ko.observable data?.id_with_prefix
      @properties = ko.observable data?.properties
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @locationText = ko.computed =>
        @lat() + ", " + @lng()
      navigator.geolocation.getCurrentPosition(@getLocation)

    getLocation: (position) =>
      @lat(position.coords.latitude)
      @lng(position.coords.longitude)

    copyPropertiesFromCollection: () =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in window.model.fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        if field.value()
          value = field.value()
          
          @properties()[field.esCode] = value
          console.log @properties()
        else
          delete @properties()[field.esCode]

    post: (json, callback) =>
      callback_with_updated_at = (data) =>
        callback(data) if callback && typeof(callback) == 'function'
      data = {site: JSON.stringify json}
      $.post "/collections/#{window.model.collectionId()}/sites", data, callback_with_updated_at
    
    toJSON: =>
      json =
        id: @id()
        name: @name()
      json.lat = @lat() if @lat()
      json.lng = @lng() if @lng()
      json.properties = @properties() if @properties()
      json



