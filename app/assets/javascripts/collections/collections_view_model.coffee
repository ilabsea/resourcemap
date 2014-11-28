onCollections ->

  class @CollectionsViewModel

    @constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @fullscreen = ko.observable(false)
      @fullscreenExpanded = ko.observable(false)
      @selectedQuery = ko.observable()
      @getAlertConditions()
      @currentSnapshot = ko.computed =>
        @currentCollection()?.currentSnapshot

    @findCollectionById: (id) -> (x for x in @collections() when x.id == parseInt id)[0]

    @tokenize: (str) ->
      results = []
      tokenRegExp = /\s*([A-Za-z]+|[0-9]+|\S)\s*/g
      m = undefined
      while (m = tokenRegExp.exec(str)) != null
        results.push m[1]
      results

    @refineFormula: ->
      res = ""
      formula = @selectedQuery()?.formula ? ""
      tokens = @tokenize(formula)
      for t in tokens
        res += " " + t
      return res

    @refineFilters: ->
      @filters([])
      conditions = @selectedQuery()?.conditions ? []
      @formula = @refineFormula() #add space to each token of formula
      filters = []
      for condition in conditions
        if condition.field_id == 'update'
          if condition.field_value == 'last_hour'
            filters.push(new FilterByLastHour(condition.id))
          else if condition.field_value == 'last_day'
            filters.push(new FilterByLastDay(condition.id))
          else if condition.field_value == 'last_week'
            filters.push(new FilterByLastWeek(condition.id))
          else if condition.field_value == 'last_month'
            filters.push(new FilterByLastMonth(condition.id))
        else if condition.field_id == 'location_missing'
          filters.push(new FilterByLocationMissing(condition.id))
        else

          if @currentCollection().fields().length > 0
            field = @currentCollection().findFieldByEsCode(condition.field_id)
            if field.kind == 'text' || field.kind == 'phone' || field.kind == 'email' || field.kind == 'user'
              filters.push(new FilterByTextProperty(field, condition.operator, condition.field_value, condition.id))
            else if field.kind == 'numeric'
              filters.push(new FilterByNumericProperty(field, condition.operator, condition.field_value, condition.id))
            else if field.kind == 'yes_no'
              filters.push(new FilterByYesNoProperty(field, condition.field_value, condition.id))
            else if field.kind == 'date'
              filters.push(new FilterByDateProperty(field, condition.operator, condition.field_date_from, condition.field_date_to, condition.id))
            else if field.kind == 'hierarchy'
              filters.push(new FilterByHierarchyProperty(field, "under", condition.field_value, "", condition.id))
            else if field.kind == 'select_one' || field.kind == 'select_many'
              filters.push(new FilterBySelectProperty(field, condition.field_value, "", condition.id))
            else if field.kind == 'site'
              id = @currentCollection().findSiteIdByName(condition.field_value)
              filters.push(new FilterBySiteProperty(field, condition.operator, condition.field_value, id, condition.id))

      @filters(filters)

    @goToRoot: ->
      @filters([])
      @selectedQuery(null)
      @queryParams = $.url().param()
      @exitSite() if @editingSite()
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
      window.model.hideLoadingField()
      # Return undefined because otherwise some browsers (i.e. Miss Firefox)
      # would render the Object returned when called from a 'javascript:___'
      # value in an href (and this is done in the breadcrumb links).
      undefined

    @deleteMembership: () =>
      alert 'delete'

    @enterCollection: (collection) ->
      window.model.loadingFields(true)
      window.model.loadingSitePermission(true)
      if @showingAlert()
        return if !collection.checked()
      else
        if typeof collection != 'string'
          collection.hasMoreSites(true)
          collection.sitesPage = 1
          collection.sites([])
          collection.siteIds = []

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
      collection.fetchQueries()
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
        if @currentCollection().fields()
          window.model.loadingFields(false)
        if @currentCollection().sitesPermission
          window.model.loadingSitePermission(false)
        window.model.enableCreateSite()

      $('.BreadCrumb').load("/collections/breadcrumbs", { collection_id: collection.id })
      window.adjustContainerSize()
      window.model.updateSitesInfo()
      @showRefindAlertOnMap()

      if @filters().length == 0
        window.model.formula = undefined
        @filters([])
      @getAlertConditions()
      $('#createSite').addClass('disabled')
      window.model.enableCreateSite()

    @editCollection: (collection) -> window.location = "/collections/#{collection.id}"

    @openShareUrlDialog:  ->
      path_share = "/collections/#{@currentCollection().id}/sites/#{@editingSite().uuid}/share"
      share_url = "#{window.location.protocol}//#{window.location.host}#{path_share}"

      path_pdf = "/collections/#{@currentCollection().id}/sites/#{@editingSite().uuid}/pdf"
      download_url = "#{window.location.protocol}//#{window.location.host}#{path_pdf}"

      $('#share-url-dialog').attr('href', share_url).text(share_url)
      $('#download-pdf').attr('href', download_url)
      $("#rm-share-url-dialog").rmDialog().show()

    @getPdf: (event)->
      path_pdf = "/site_pdfs"
      data = {id: @editingSite().uuid}
      $.post path_pdf, data,  ()=>
        $.status.showNotice(window.t('javascripts.collections.index.pdf_generating'), 60*1000)
      event.preventDefault()

    @openDialog:  ->
      $("#rm-download-history-dialog").rmDialog().show()
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
          window.model.selectedQuery(@setSelectedQuery()) if @filters().length > 0
      else
        $.get "/plugin/alerts/thresholds.json", (data) =>
          for collection in @collections()
            thresholds = collection.fetchThresholds(data)
            collection.thresholds(thresholds)

    @hideDatePicker: ->
      $("input").datepicker "hide"

    @setSelectedQuery: ->
      query = window.model.selectedQuery()
      for q in @currentCollection().queries()
        if query.id == q.id
          return q
