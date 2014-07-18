onCollections ->

  class @CollectionsViewModel

    @constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @fullscreen = ko.observable(false)
      @fullscreenExpanded = ko.observable(false)
      @currentSnapshot = ko.computed =>
        @currentCollection()?.currentSnapshot

    # @findCollectionById: (id) -> (x for x in @collections() when x.id == id)[0]
    @findCollectionById: (id) -> (x for x in @collections() when x.id == parseInt id)[0]
    
    @goToRoot: ->
      @queryParams = $.url().param()
      @exitSite() if @editingSite()
      @currentCollection(null)
      @unselectSite() if @selectedSite()
      @search('')
      @lastSearch(null)
      @filters([])
      @sort(null)
      @sortDirection(null)
      @groupBy(@defaultGroupBy)

      initialized = @initMap()
      @reloadMapSites() unless initialized
      @refreshTimeago()
      @makeFixedHeaderTable()

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
      if typeof scollection == 'string'
        collection = @findCollectionById parseInt(collection)


      @currentCollection collection
      @unselectSite() if @selectedSite()
      @exitSite() if @editingSite()
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
          $(".oleftexpand").removeClass("oleftexpand")
          @reloadMapSites()


    @createCollection: -> window.location = "/collections/new"
