onCollections ->

  class @SitesViewModel
    @constructor: ->
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @selectedHierarchy = ko.observable()
      @loadingSite = ko.observable(false)
      @loadingFields = ko.observable(false)
      @loadingSitePermission = ko.observable(false)
      @newOrEditSite = ko.computed => if @editingSite() && (!@editingSite().id() || @editingSite().inEditMode()) then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().inEditMode() then @editingSite() else null
      @allFieldLogics = ko.observableArray()
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
      if window.model.editingSite()
        fields = window.model.editingSite().fields()
      else if window.model.currentCollection()
        fields = window.model.currentCollection().fields()
      for field in fields
        if field.kind == 'location'
          result = [{name: window.t('javascripts.collections.fields.no_value'), code: ''}]
          for location in field.locations
            distance = @calculateDistance(fromLat, fromLng, location.latitude, location.longitude)
            if distance < parseFloat(field.maximumSearchLength)
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
        @showLoadingField()
        if window.model.loadingFields()
          $.get "/collections/#{@currentCollection().id}/fields", {}, (data) =>
            window.model.loadingFields(false)
            @currentCollection().layers($.map(data, (x) => new Layer(x)))

            fields = []
            for layer in @currentCollection().layers()
              for field in layer.fields
                fields.push(field)

            @currentCollection().fields(fields)
            @prepareNewSite(site, pos)
        else
          @prepareNewSite(site, pos)

    @prepareNewSite: (site, pos) ->
      site.copyPropertiesToCollection(@currentCollection())
      if window.model.newSiteProperties
        for esCode, value of window.model.newSiteProperties
          field = @currentCollection().findFieldByEsCode esCode
          field.setValueFromSite(value) if field

      @unselectSite()
      @editingSite site
      @editingSite().startEditLocationInMap()
      @getLocations(pos.lat, pos.lng)
      window.model.initDatePicker()
      window.model.initAutocomplete()
      window.model.initControlKey()
      window.model.newOrEditSite().scrollable(false)
      window.model.newOrEditSite().startEntryDate(new Date(Date.now()))
      for field in window.model.newOrEditSite().fields()
        new CustomWidget(field).bindField() if field.isForCustomWidget
        field.disableDependentSkipLogicField() if field.skippedState() == false && field.kind == 'yes_no'
        if field.field_logics
          for f in field.field_logics
            f["disable_field_id"] = field["esCode"]
            @allFieldLogics(@allFieldLogics().concat(f))
      site.prepareCalculatedField()

      $('#name').focus()
      @hideLoadingField()

    @editSite: (site) ->
      initialized = @initMap()
      site.collection.panToPosition(true) unless initialized
      site.collection.fetchSitesMembership()
      @showLoadingField()
      @allFieldLogics([])
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
            @currentCollection(site.collection)
            @loadBreadCrumb()
            @reinitialFields()
            @processSkipLogic()

          $('a#previewimg').fancybox()

    @reinitialFields: ->
      @allFieldLogics([])
      for field in @editingSite().fields()
        field.bindWithCustomWidgetedField()
        field.dependentHierarchyItemList(field.initDependentHierarchyItemList()) if field.isDependentFieldHierarchy()
        field.valid() if field.is_enable_custom_validation
        @getLocations(@editingSite().lat(), @editingSite().lng()) if field.kind == 'location'
        field.inititalFieldLogic() if field.field_logics.length > 0

    @processSkipLogic: ->
      for field in @editingSite().fields()
        field.disableDependentSkipLogicField()

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
      $(".tablescroll").css({opacity: 0.2})
      $('#uploadProgress').fadeIn()
      $(".tablescroll :input").attr("disabled", true)

    @hideProgress: ->
      $(".tablescroll").css({opacity: 1})
      $('#uploadProgress').fadeOut()
      $(".tablescroll :input").removeAttr('disabled')

    @showLoadingField: ->
      $(".tablescroll").css({opacity: 0.2})
      $('#loadProgress').fadeIn()
      $(".tablescroll :input").attr("disabled", true)

    @hideLoadingField: ->
      $(".tablescroll").css({opacity: 1})
      $('#loadProgress').fadeOut()
      $(".tablescroll :input").removeAttr('disabled')

    @enableCreateSite: ->
      if window.model.loadingFields() == false && window.model.loadingSitePermission() == false
        $('#createSite').removeClass('disabled')

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
          @reinitialFields()
        else
          @editingSite().deleteMarker()
          @exitSite()

        $('a#previewimg').fancybox()
        window.model.updateSitesInfo()
        @reloadMapSites()

      callbackError = (error) =>
        @hideProgress()

      @editingSite().copyPropertiesFromCollection(@currentCollection())
      @editingSite().fillPhotos(@currentCollection())

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
        @reinitialFields()
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

      @loadBreadCrumb()
      @rewriteUrl()

      window.model.hideLoadingField()
      $('a#previewimg').fancybox()
      # Return undefined because otherwise some browsers (i.e. Miss Firefox)
      # would render the Object returned when called from a 'javascript:___'
      # value in an href (and this is done in the breadcrumb links).
      undefined

    @previewSite: ->
      url = "collections/#{@currentCollection().id}/sites/#{@editingSite().id()}"
      window.location.href = url
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

    @prepareCalculatedField: ->
      for layer in window.model.currentCollection().layers()
        for field in layer.fields
          if field["kind"] == "calculation"
            # Replace $field code to actual jQuery object
            $.map(field["dependentFields"], (f) ->
              fieldName = "$" + f["code"]
              fieldValue = "$" + f["code"]
              switch f["kind"]
                when "text", "email", "phone"
                  fieldValue = "$('#" + f["kind"] + "-input-" + f["code"] + "').val()"
                when "numeric"
                  fieldValue = "parseInt($('#" + f["kind"] + "-input-" + f["code"] + "').val())"
                when "select_one"
                  fieldValue = "$('#" + f["kind"] + "-input-" + f["code"] + " option:selected').text()"
                when "yes_no"
                  fieldValue = "$('#" + f["kind"] + "-input-" + f["code"] + "')[0].checked"
              field["codeCalculation"] = field["codeCalculation"].replace(new RegExp(fieldName.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1"), 'g'), fieldValue);

            )
            # Add change value to dependent field
            $.map(field["dependentFields"], (f) ->
              # element_id = "#" +field["kind"] + "-input-" + field["code"]
              element_id = field["code"]
              $.map(window.model.editingSite().fields(), (fi) ->
                if fi.code == element_id
                  execute_code = field["codeCalculation"]
                  $("#" + f["kind"] + "-input-" + f["code"]).on("change", ->
                    $.map(window.model.editingSite().fields(), (fi) ->
                      if fi.code == element_id
                        fi.value(eval(execute_code))
                    )
                  )
              )
            )
