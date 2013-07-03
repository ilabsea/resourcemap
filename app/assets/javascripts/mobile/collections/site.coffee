onMobileCollections ->
  class @Site
    constructor: (collection, data) ->
      @collection = collection
      @selected = ko.observable()
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @idWithPrefix = ko.observable data?.id_with_prefix
      @properties = ko.observable data?.properties
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @photos = {}

      @locationValid = ko.observable(true)
      @locationText = ko.computed =>
      @nameError  = ko.computed => "Site's Name is missing " if $.trim(@name()).length == 0
      @latError = ko.computed =>  "Site location's lat is missing" if $.trim(@lat()).length == 0
      @lngError = ko.computed => "Site location;s lng is missing" if $.trim(@lng()).length == 0 
      @error = ko.computed => @nameError() ? @latError() ? @lngError()
      @valid = ko.computed => !@error()
      @saveFailed = ko.observable(false)
      @errorMessage = ko.observable("")
      navigator.geolocation.getCurrentPosition(@getLocation, @showError)

    getLocation: (position) =>
      @lat(position.coords.latitude)
      @lng(position.coords.longitude)

    showError: (error) =>
      switch error.code
        when error.PERMISSION_DENIED
          @lat('')
          @lng('')
          @locationValid(false)
          #x.innerHTML = "User denied the request for Geolocation."
        when error.POSITION_UNAVAILABLE
          @lat('')
          @lng('')
          @locationValid(false)
          #x.innerHTML = "Location information is unavailable."
        when error.TIMEOUT
          @lat('')
          @lng('')
          @locationValid(false)
        when error.UNKNOWN_ERROR
          @lat('')
          @lng('')
          @locationValid(false)
          #x.innerHTML = "An unknown error occurred."

    fillPhotos: (collection) =>
      for field in collection.fields()
        if field.kind == 'photo' && field.value() 
          @photos[field.value()] = field.photo

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in collection.fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        if field.value()
          value = field.value()
          
          @properties()[field.esCode] = value
        else
          delete @properties()[field.esCode]

    post: (json, callback) =>
      callback_with_updated_at = (data) =>
        callback(data) if callback && typeof(callback) == 'function'

      failed_callback = (data) =>
        failed(data) if failed && typeof(callback) == 'function'
      data = {site: JSON.stringify json}

      if JSON.stringify(@photos) != "{}"
        data["fileUpload"] = @photos

      if window.navigator.onLine
        console.log("Online: store now")
        $.post("collections/#{@collection.id}/sites", data, callback_with_updated_at)
      else
        if window.localStorage.getItem("cachedSites") is null
          window.localStorage.setItem("cachedSites", JSON.stringify([]))

        cachedSites = JSON.parse(window.localStorage.getItem("cachedSites"))
        siteRequest =
          id: Math.floor(Math.random()*9000000000000) + 1000000000000
          endpoint: "collections/#{@collection.id}/sites"
          data: data

        cachedSites.push siteRequest
        window.localStorage.setItem("cachedSites", JSON.stringify(cachedSites))
        window.model.currentCollection(null) 
        window.model.newOrEditSite(null)

    copyPropertiesToCollection: (collection) =>
      collection.fetchFields =>
        collection.clearFieldValues()
        if @properties()
          for field in collection.fields()
            value = @properties()[field.esCode]

            field.value(value)


    toJSON: =>
      json =
        id: @id()
        name: @name()
      json.lat = @lat() if @lat()
      json.lng = @lng() if @lng()
      json.properties = @properties() if @properties()
      json
