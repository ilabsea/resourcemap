onCollections ->
  MainViewModel.include class
    @constructor: ->
      @alertsCount = ko.observable(0)
      @showingAlert= ko.observable(false)
      @alertsCountText = ko.computed => if @alertsCount() == 1 then '1 alert' else "#{@alertsCount()} alerts"

      @onSitesChanged =>
        if @currentCollection()
          @getThresholds()        
        alertsCount = 0
        bounds = @map.getBounds()
        for siteId, marker of @markers
          if bounds.contains marker.getPosition()
            alertsCount += 1 if marker.site?.alert == "true"
        for clusterId, cluster of @clusters
          if bounds.contains cluster.position
            alertsCount += cluster.data.alert_count
        alertsCount += 1 if @selectedSite()?.alert?()
        @alertsCount alertsCount
      @aliasMethodChain "setMarkerIcon", "Alerts"

    @setMarkerIconWithAlerts: (marker, icon) ->
      if marker.site && marker.site.alert == 'true' && icon == 'active'
        marker.setIcon @markerImage 'markers/resmap_' + @alertMarker(marker.site.color)  + '_' + marker.site.icon + @endingUrl(icon) + '.png'
        #marker.setIcon @markerImage marker.site.icon
        marker.setShadow null
      else
        @setMarkerIconWithoutAlerts(marker, icon)

    @clearCheckedCollections: () ->
      for collection in @collections()
        collection.checked(false)

    @filterAlertedSites: () ->
      @showingAlert(true) 
      if @currentCollection()
        @currentCollection().hasMoreSites(true)
        @currentCollection().siteIds = {}
        @currentCollection().sites([])
        @currentCollection().sitesPage = 1 
        @enterCollection(@currentCollection())
      else
        @getAlertedCollections()

    @getAlertedCollections: () ->
      return unless @showingAlert()
      collection_ids = $.map @collections(), (c) -> 
        c.id if c.checked()
      $.get "collections/alerted-collections.json", ids: collection_ids, (data) =>
        @clearCheckedCollections()
        for collection in @collections()
          @resetCollectionStatus(collection)
          for d in data
            if collection.id == d
              collection.checked(true)

    @cancelFilterAlertedSites: () ->

      @showingAlert(false)
      if @currentCollection()
        @resetCollectionStatus(@currentCollection()) 
        @enterCollection(@currentCollection())
      else
        for collection in @collections()
          @resetCollectionStatus(collection)
          if collection.checked() == true
            collection.checked(false)
            collection.checked(true)
      @rewriteUrl()


    @resetCollectionStatus: (collection) ->
      collection.hasMoreSites(true)
      collection.sitesPage = 1
      collection.sites([])
      collection.siteIds = []


