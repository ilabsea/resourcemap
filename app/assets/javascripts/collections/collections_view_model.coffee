onCollections ->

  class @CollectionsViewModel

    @constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @showingLegend = ko.observable(false)
      @fullscreen = ko.observable(false)
      @fullscreenExpanded = ko.observable(false)
      @getAlertConditions()
      @currentSnapshot = ko.computed =>
        @currentCollection()?.currentSnapshot

    @findCollectionById: (id) -> (x for x in @collections() when x.id == parseInt id)[0]
    
    @goToRoot: ->
      @queryParams = $.url().param()
      @filters([])
      @exitSite() if @editingSite()
      @exitSite() if @selectedSite()
      @unselectSite() if @selectedSite()
      @currentCollection(null)
      @showingAlert(false)
      @cancelFilterAlertedSites()
      @search('')
      @lastSearch(null)
      @sort(null)
      @sortDirection(null)
      @groupBy(@defaultGroupBy)
      initialized = @initMap()
      @reloadMapSites() unless initialized
      @refreshTimeago()
      @makeFixedHeaderTable()
      @hideRefindAlertOnMap()
      @rewriteUrl()

      $('.BreadCrumb').load("/collections/breadcrumbs", {})

      @getAlertedCollections()
      window.setTimeout(window.adjustContainerSize, 100)

      # Return undefined because otherwise some browsers (i.e. Miss Firefox)
      # would render the Object returned when called from a 'javascript:___'
      # value in an href (and this is done in the breadcrumb links).
      undefined

    @deleteMembership: () =>
      alert 'delete'

    @enterCollection: (collection) ->
      if @showingAlert()
        return if !collection.checked()      
      @queryParams = $.url().param()

      # collection may be a collection object (in most of the cases)
      # or a string representing the collection id (if the collection is being loaded from the url)
      if typeof collection == 'string'
        collection = @findCollectionById parseInt(collection)

      @currentCollection collection
      @unselectSite() if @selectedSite()
      @exitSite() if @editingSite()   

      @currentCollection().checked(true)
      if @showingAlert()
        $.get "/collections/#{@currentCollection().id}/sites_by_term.json", _alert: true, (sites) =>
          @currentCollection().allSites(sites)
          window.adjustContainerSize()
          
      else
        $.get "/collections/#{@currentCollection().id}/sites_by_term.json", (sites) =>
          @currentCollection().allSites(sites)
          window.adjustContainerSize()

      initialized = @initMap()
      collection.panToPosition(true) unless initialized

      collection.fetchSitesMembership()
      collection.fetchFields =>
        if @processingURL
          @processURL()
        else
          @ignorePerformSearchOrHierarchy = false
          @performSearchOrHierarchy()
          @refreshTimeago()
          @makeFixedHeaderTable()
          @rewriteUrl()

        window.adjustContainerSize()
      $('.BreadCrumb').load("/collections/breadcrumbs", { collection_id: collection.id })
      window.adjustContainerSize()
      window.model.updateSitesInfo()
      @showRefindAlertOnMap()
      @getAlertConditions()
      @filters([])

    @editCollection: (collection) -> window.location = "/collections/#{collection.id}"

    @openDialog:  ->
      $(".rm-dialog").rmDialog().show()
      $("#rm-colllection_id").val(@currentCollection().id)

    @tooglefullscreen: ->
      if !@fullscreen()
        @fullscreen(true)
        $("body").addClass("fullscreen")
        $(".ffullscreen").addClass("frestore")
        $(".ffullscreen").removeClass("ffullscreen")
        $('.expand-collapse_button').show()
        $(".expand-collapse_button").addClass("oleftcollapse")
        $(".expand-collapse_button").removeClass("oleftexpand")
        window.adjustContainerSize()
        @reloadMapSites()
      else
        @fullscreen(false)
        @fullscreenExpanded(false)
        $("body").removeClass("fullscreen")
        $(".frestore").addClass("ffullscreen")
        $(".frestore").removeClass("frestore")
        $('#collections-main .left').show()
        $('.expand-collapse_button').hide()
        window.adjustContainerSize()
        @reloadMapSites()
      @makeFixedHeaderTable()

      window.setTimeout(window.adjustContainerSize, 200)

    @toogleExpandFullScreen: ->
      if @fullscreen() && !@fullscreenExpanded()
        @fullscreenExpanded(true)
        $('#collections-main .left').hide()
        window.adjustContainerSize()
        $(".oleftcollapse").addClass("oleftexpand")
        $(".oleftcollapse").removeClass("oleftcollapse")
        @reloadMapSites()

      else
        if @fullscreen() && @fullscreenExpanded()
          @fullscreenExpanded(false)
          $('#collections-main .left').show()
          window.adjustContainerSize()
          $(".oleftexpand").addClass("oleftcollapse")
          $(".oleleftexpand").removeClass("oleftexpand")
          @reloadMapSites()

    @hideRefindAlertOnMap: ->
      $('#sites_whitout_location_alert').hide()

    @showRefindAlertOnMap: ->
      $('#sites_whitout_location_alert').show()

    @createCollection: -> window.location = "/collections/new"
    
    @getAlertConditions: ->
      if @currentCollection()
        $.get "/plugin/alerts/collections/#{@currentCollection().id}/thresholds.json", (data) =>
          thresholds = @currentCollection().fetchThresholds(data)
          @currentCollection().thresholds(thresholds)
      else
        $.get "/plugin/alerts/thresholds.json", (data) =>   
          for collection in @collections()
            if collection.checked() == true
              thresholds = collection.fetchThresholds(data)
              collection.thresholds(thresholds)

    @hideDatePicker: ->
      $("input").datepicker "hide"
