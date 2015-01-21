#= require module
#= require collections/locatable
#= require collections/sites_container
#= require collections/sites_membership
#= require collections/layer
#= require collections/fields/field
#= require collections/query
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
      @isPublishedTemplate = data?.is_published_template
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
      @loadSites() unless window.currentUserIsGuest

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

    findSitesByThresholds: (thresholds) =>
      alertSites = []
      b = false
      for key,threshold of thresholds
        if threshold.alertSites().length > 0
          sites = threshold.alertSites()
        else
          sites = this.sites()
        for site in sites
          site = @findSiteById(site.collection.id, threshold.collectionId) if threshold.isAllSite() == "false"
          alertSite = this.operateWithCondition(threshold.conditions(), site, threshold.isAllCondition()) if site?
          if alertSite? && alertSites.indexOf(alertSite) == -1
            b = true
            alertSites.push(alertSite)
            thresholds[key].alertedSitesNum(thresholds[key].alertedSitesNum()+1)
            window.model.showingLegend(true)
            @showLegend(true)
          else
            b = false
      for key,threshold of thresholds
        if threshold.alertedSitesNum() == 0
          thresholds.splice(key,1)
      return thresholds

    operateWithCondition: (conditions, site, isAllCondition) =>
      b = true
      for key, condition of conditions
        operator = condition.op().code()
        if condition.valueType().code() is 'percentage'
          percentage = (site?.properties()[condition.compareField()] * condition.value())/100
          compareField = percentage
        else
          compareField = condition.value()
          
        field = site?.properties()[condition.field()]
        switch operator
          when "eq"
            if field is compareField
              b = true
            else
              b = false
          when "eqi"
            if field?.toLowerCase() is compareField.toLowerCase()
              b = true
            else
              b = false
          when "gt"
            if field > compareField
              b = true
            else
              b = false   
          when "lt"
            if field < compareField
              b = true
            else
              b = false
          when "con"
            if typeof field != 'undefined' && field.toLowerCase().indexOf(compareField.toLowerCase()) != -1
              b = true
            else
              b = false                   
          else
            null
        if isAllCondition == "true"
          return null if b == false            
        else
          return site if b == true            
          return null if b == false && parseInt(key) == conditions.length-1

      return site

    loadCurrentSnapshotMessage: =>
      @viewingCurrentSnapshotMessage = ko.observable()
      @viewingCurrentSnapshotMessage("You are currently viewing this collection's data as it was on snapshot " + @currentSnapshot + ".")

    fetchQueries: (callback) =>
      $.get "/collections/#{@id}/queries.json", {}, (data) =>
        @queries($.map(data, (x) => new Query(x)))

        callback() if callback && typeof(callback) == 'function'

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      window.model.loadingFields(true)
      $.get "/collections/#{@id}/fields", {}, (data) =>
        @layers($.map(data, (x) => new Layer(x)))

        fields = []
        for layer in @layers()
          for field in layer.fields
            fields.push(field)

        @fields(fields)
        @refineFields(fields)
        window.model.loadingFields(false)
        window.model.enableCreateSite()

    decodeField: (str) =>
      dict = {}
      data = (str + '').split('')
      currChar = data[0]
      oldPhrase = currChar
      out = [ currChar ]
      code = 256
      phrase = undefined
      i = 1
      while i < data.length
        currCode = data[i].charCodeAt(0)
        if currCode < 256
          phrase = data[i]
        else
          phrase = if dict[currCode] then dict[currCode] else oldPhrase + currChar
        out.push phrase
        currChar = phrase.charAt(0)
        dict[code] = oldPhrase + currChar
        code++
        oldPhrase = phrase
        i++
      out.join ''


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
