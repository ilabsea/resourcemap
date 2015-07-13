onCollections ->

  class @SitesViewModel
    @constructor: ->
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @selectedHierarchy = ko.observable()
      @loadingSite = ko.observable(false)
      @newOrEditSite = ko.computed => if @editingSite() && (!@editingSite().id() || @editingSite().inEditMode()) then @editingSite() else null
      @showSite = ko.computed =>  if @editingSite()?.id() && !@editingSite().inEditMode() then @editingSite() else null
      window.markers = @markers = {}
      
    @loadBreadCrumb: ->
      params = {}
      if @selectedSite()
        params["site_name"] = @selectedSite().name() # send the site's name to avoid having to make a server side query for it
        params["site_id"] = @selectedSite().id()
      params["collection_id"] = @currentCollection().id if @currentCollection()

      $('.BreadCrumb').load("/collections/breadcrumbs", params)
    @editingSiteLocation: ->
      @editingSite() && (!@editingSite().id() || @editingSite().inEditMode() || @editingSite().editingLocation())

    @calculateDistance: (fromLat, fromLng, toLat, toLng) => 
      fromLatlng = new google.maps.LatLng(fromLat, fromLng)
      toLatlng = new google.maps.LatLng(toLat, toLng)
      distance = google.maps.geometry.spherical.computeDistanceBetween(fromLatlng, toLatlng)
      return distance

    @getLocations: (fromLat, fromLng) =>
      if window.model.selectedSite()
        fields = window.model.selectedSite().fields()
        fromLat = window.model.selectedSite().lat()
        fromLng = window.model.selectedSite().lng()
      else if window.model.currentCollection()
        fields = window.model.currentCollection().fields()

      for field in fields
        if field.kind == 'location'
          result = []

          for location in field.locations
            distance = @calculateDistance(fromLat, fromLng, location.latitude, location.longitude)
            if distance < parseFloat(field.maximumSearchLength)
              location.distance = distance
              result.push(location)
          result.sort (a, b) => 
            return parseFloat(a.distance) - parseFloat(b.distance)

          result.splice(20, result.length)
          field.resultLocations(result)

    @createSite: ->
      @goBackToTable = true unless @showingMap()
      @showMap =>
        if !@currentPosition.lat
          @handleNoGeolocation()

        pos = @originalSiteLocation = @currentPosition
        site = new Site(@currentCollection(), lat: pos.lat, lng: pos.lng)
        site.copyPropertiesToCollection(@currentCollection())
        if window.model.newSiteProperties
          for esCode, value of window.model.newSiteProperties
            field = @currentCollection().findFieldByEsCode esCode
            field.setValueFromSite(value) if field
        
        #set default value to field yes_no as false
        if site
          for field in site.fields()
            if field.kind == 'yes_no'
              field.setDefaultValueToYesNoField()

        #update @currentCollection().allSite()
        fields = @currentCollection().fields()
        for field in fields 
          if field.kind == 'site'
            @loadSiteByTerm(@showingAlert())

        @unselectSite()
        @editingSite site
        @editingSite().startEditLocationInMap() if @currentCollection().isVisibleLocation
        @getLocations(pos.lat, pos.lng)
        window.model.initDatePicker()
        window.model.initAutocomplete()
        $('textarea').autogrow()
        $('#name').focus()

    @editSite: (site) ->
      #update @currentCollection().allSite()
      fields = @currentCollection().fields()
      for field in fields 
        if field.kind == 'site'
          @loadSiteByTerm(@showingAlert())

      initialized = @initMap()
      site.collection.panToPosition(true) unless initialized
      window.model.map.setZoom(12)

      site.collection.fetchSitesMembership()
      site.collection.fetchFields =>
        if @processingURL
          @processURL()
        else
          @goBackToTable = true unless @showingMap()
          @showMap =>

            site.copyPropertiesToCollection(site.collection)
            
            if @selectedSite() && @selectedSite().id() == site.id()
              @unselectSite()

            if site.collection.sitesPermission.canUpdate(site) || site.collection.sitesPermission.canRead(site)
              site.fetchFields()
            else if site.collection.sitesPermission.canNone(site)
              site.layers([]) 

            @selectSite(site)
            @editingSite(site)
            @getLocations(site.lat(), site.lng())
            @currentCollection(site.collection)
            @loadBreadCrumb()

          $('a#previewimg').fancybox()
          $('#name').focus()

    @editSiteFromId: (siteId, collectionId) ->
      site = @siteIds[siteId]
      if site
        @editSite site
      else
        @loadingSite(true)
        $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(collectionId)
          site = new Site(collection, data)
          site = collection.addSite(site)
          @editSite site

    @selectSiteFromId: (siteId, collectionId) ->
      site = @siteIds[siteId]
      if site
        @selectSite site
      else
        @loadingSite(true)
        $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(collectionId)
          # Data will be empty if site is not found
          if !$.isEmptyObject(data)
            site = new Site(collection, data)
            site = collection.addSite(site)
            @selectSite site
          else
            @enterCollection(collection)

    @editSiteFromMarker: (siteId, collectionId) ->
      @exitSite() if @editingSite()
      # Remove name popup if any
      window.model.markers[siteId].popup.remove() if window.model.markers[siteId]?.popup
      site = @siteIds[siteId]
      if site
        @editSite site
      else
        @loadingSite(true)
        if @selectedSite() && @selectedSite().marker
          @setMarkerIcon @selectedSite().marker, 'active'
        $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(collectionId)
          site = new Site(collection, data)
          @editSite site

    @showProgress: ->
      $("#editorContent").css({opacity: 0.2})
      $('#uploadProgress').fadeIn()
      $("#editorContent :input").attr("disabled", true)

    @hideProgress: ->
      $("#editorContent").css({opacity: 1})
      $('#uploadProgress').fadeOut()
      $("#editorContent :input").removeAttr('disabled')

    @saveSite: ->
      return unless @editingSite().valid()
      @showProgress()
      callback = (data) =>
        @hideProgress()

        @currentCollection().reloadSites()

        @editingSite().updatedAt(data.updated_at)

        @editingSite().position(data)
        @currentCollection().fetchLocation()

        if @editingSite().inEditMode()
          @editingSite().exitEditMode(true)
        else
          @editingSite().deleteMarker()
          @exitSite()

        $('a#previewimg').fancybox()
        window.model.updateSitesInfo()
        @reloadMapSites()

      callbackError = () =>
        @hideProgress()

      @editingSite().copyPropertiesFromCollection(@currentCollection())
      @editingSite().fillPhotos(@currentCollection())
      @editingSite().roundNumericDecimalNumber(@currentCollection)

      if @editingSite().id()
        @editingSite().update_site(@editingSite().toJSON(), callback, callbackError)
      else
        @editingSite().create_site(@editingSite().toJSON(), callback, callbackError)

    @exitSite: ->
      if !@editingSite()?.inEditMode()
        @performSearchOrHierarchy()

      field.exitEditing() for field in @currentCollection().fields()
      if @editingSite()?.inEditMode()
        @editingSite().exitEditMode()
        @exitSite() if @selectedSite()
      else
        if @editingSite()
          # Unselect site if it's not on the tree
          @editingSite().editingLocation(false)
          @editingSite().deleteMarker() unless @editingSite().id()
          @editingSite(null)
          window.model.setAllMarkersActive()
          if @goBackToTable
            @showTable()
            delete @goBackToTable
          else
            @reloadMapSites()
        window.model.map.setZoom(3)

      @loadBreadCrumb()
      @rewriteUrl()

      $('a#previewimg').fancybox()
      # Return undefined because otherwise some browsers (i.e. Miss Firefox)
      # would render the Object returned when called from a 'javascript:___'
      # value in an href (and this is done in the breadcrumb links).
      undefined

    @deleteSite: ->
      if confirm("Are you sure you want to delete #{@editingSite().name()}?")
        @unselectSite()
        @currentCollection().removeSite(@editingSite())
        $.post "/sites/#{@editingSite().id()}", {collection_id: @currentCollection().id, _method: 'delete'}, =>
          @currentCollection().fetchLocation()
          @editingSite().deleteMarker()
          @exitSite()
          @reloadMapSites() if @showingMap()
          window.model.updateSitesInfo()

    @selectSite: (site) ->
      if @selectedHierarchy()
          @selectedHierarchy(null)
      if @showingMap()
        if @selectedSite()
          if @selectedSite().marker
            @oldSelectedSite = @selectedSite()
            @setMarkerIcon @selectedSite().marker, 'active'
            @selectedSite().marker.setZIndex(@zIndex(@selectedSite().marker.getPosition().lat()))
          @selectedSite().selected(false)

        if @selectedSite() == site
          @selectedSite(null)
          @reloadMapSites()
        else
          @selectedSite(site)

          @selectedSite().selected(true)
          if @selectedSite().id() && @selectedSite().hasLocation()
            # Again, all these checks are to prevent flickering
            if @markers[@selectedSite().id()]
              @selectedSite().marker = @markers[@selectedSite().id()]
              @selectedSite().marker.setZIndex(200000)
              @setMarkerIcon @selectedSite().marker, 'target'
              @deleteMarker @selectedSite().id(), false
            else
              @selectedSite().createMarker()
            @selectedSite().panToPosition()
          else if @oldSelectedSite
            @oldSelectedSite.deleteMarker()
            delete @oldSelectedSite
            @reloadMapSites()
      else
        @selectedSite().selected(false) if @selectedSite()
        if @selectedSite() == site
          @selectedSite(null)
        else
          @selectedSite(site)

      @rewriteUrl()


    @selectHierarchy: (hierarchy) ->
      if @selectedSite()
        @unselectSite()
      @selectedHierarchy(hierarchy)

    @unselectSite: ->
      @selectSite(@selectedSite()) if @selectedSite()
