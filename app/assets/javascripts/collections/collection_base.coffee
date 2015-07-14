#= require module
#= require collections/locatable
#= require collections/sites_container
#= require collections/sites_membership
#= require collections/layer
#= require collections/field
#= require collections/thresholds/condition
onCollections ->

  class @CollectionBase extends Module
    @include Locatable
    @include SitesContainer
    @include SitesMembership

    constructor: (data) ->
      @constructorLocatable(data)
      @constructorSitesContainer()
      @constructorSitesMembership()

      @id = data?.id
      @name = data?.name
      @icon = data?.icon
      @isVisibleName = data?.is_visible_name
      @isVisibleLocation = data?.is_visible_location
      @currentSnapshot = if data?.snapshot_name then data?.snapshot_name else ''
      @updatedAt = ko.observable(data?.updated_at)
      @showLegend = ko.observable(false)
      @showingCollectionAlert = ko.observable(false)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @loadCurrentSnapshotMessage()
      @loadAllSites()
      @loading = ko.observable(false)

    loadSites: =>
      @loading(true)
      $.get @sitesUrl(), (data) =>
        @loading(false)
        for site in data
          @addSite @createSite(site) 

    loadAllSites: =>
      @allSites = ko.observable()

    findSiteById: (value, collectionId) =>
      if window.model.currentCollection()?
        sites = window.model.currentCollection().sites()
      else
        sites = window.model.findCollectionById(collectionId).sites()
      return if not sites
      (site for site in sites when site.id() is parseInt(value))[0]

    findSiteNameById: (value) =>
      allSites = window.model.currentCollection().allSites()
      return if not allSites
      (site.name for site in allSites when site.id is parseInt(value))[0]

    findSiteIdByName: (value) =>
      id = (site for site in window.model.currentCollection().allSites() when site.name is value)[0]?.id
      id
    
    fetchThresholds: (data) =>  
      thresholds = []
      for threshold in data
        if threshold.collection_id == this.id
          threshold_new = new Threshold(threshold, this.icon)
          thresholds.push(threshold_new)
      thresholds

    loadCurrentSnapshotMessage: =>
      @viewingCurrentSnapshotMessage = ko.observable()
      @viewingCurrentSnapshotMessage("You are currently viewing this collection's data as it was on snapshot " + @currentSnapshot + ".")

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      $.get "/collections/#{@id}/fields", {}, (data) =>
        @layers($.map(data, (x) => new Layer(x)))

        fields = []
        for layer in @layers()
          for field in layer.fields
            fields.push(field)

        @fields(fields)
        @refineFields(fields)

    findFieldByCode: (code) => (field for field in @fields() when field.code == code)[0]

    findFieldByEsCode: (esCode) => (field for field in @fields() when field.esCode == esCode)[0]

    clearFieldValues: =>
      field.value(null) for field in @fields()

    propagateUpdatedAt: (value) =>
      @updatedAt(value)

    link: (format, auth_token) => "/api/collections/#{@id}.#{format}?auth_token=#{auth_token}"

    level: => -1

    setQueryParams: (q) -> q

    performHierarchyChanges: (site, changes) =>

    sitesWithoutLocation: ->
      res = (site for site in this.sites() when !site.hasLocation())
      res

    unloadCurrentSnapshot: ->
      $.post "/collections/#{@id}/unload_current_snapshot.json", ->
        window.location.reload()

    searchUsersUrl: -> "/collections/#{@id}/memberships/search.json"

    searchSitesUrl: -> "/collections/#{@id}/sites_by_term.json"

