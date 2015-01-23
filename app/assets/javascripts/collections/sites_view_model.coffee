onCollections ->

  class @SitesViewModel
    @constructor: ->
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @selectedHierarchy = ko.observable()
      @loadingSite = ko.observable(false)
      @newOrEditSite = ko.computed => if @editingSite() && (!@editingSite().id() || @editingSite().inEditMode()) then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().inEditMode() then @editingSite() else null
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

    @createSite: ->
      @goBackToTable = true unless @showingMap()
      @showMap =>
        pos = @originalSiteLocation = @map.getCenter()
        site = new Site(@currentCollection(), lat: pos.lat(), lng: pos.lng())
        site.copyPropertiesToCollection(@currentCollection())
        if window.model.newSiteProperties
          for esCode, value of window.model.newSiteProperties
            field = @currentCollection().findFieldByEsCode esCode
            field.setValueFromSite(value) if field
        @unselectSite()
        @editingSite site
        @editingSite().startEditLocationInMap()
        window.model.initDatePicker()
        window.model.initAutocomplete()
        site.prepareCalculatedField()

    @editSite: (site) ->
      initialized = @initMap()
      site.collection.panToPosition(true) unless initialized

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

            @selectSite(site)
            @editingSite(site)
            @currentCollection(site.collection)

            @loadBreadCrumb()

          $('a#previewimg').fancybox()

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

      callbackError = () =>
        @hideProgress()

      @editingSite().copyPropertiesFromCollection(@currentCollection())
      @editingSite().fillPhotos(@currentCollection())

      if @editingSite().id()
        @editingSite().update_site(@editingSite().toJSON(), callback, callbackError)
      else
        @editingSite().create_site(@editingSite().toJSON(), callback, callbackError)

    @exitSite: ->
      @editingSite().scrollable(false)
      if !@editingSite()?.inEditMode()
        @performSearchOrHierarchy()

      field.exitEditing() for field in @currentCollection().fields()
      if @editingSite()?.inEditMode()
        @editingSite().exitEditMode()
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