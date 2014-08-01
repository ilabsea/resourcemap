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
      @currentSnapshot = if data?.snapshot_name then data?.snapshot_name else ''
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @loadCurrentSnapshotMessage()
      @loadAllSites()

    loadAllSites: =>
      @allSites = ko.observable()

    findSiteNameById: (value) =>
      allSites = window.model.currentCollection().allSites()
      return if not allSites
      (site.name for site in allSites when site.id is parseInt(value))[0]

    findSiteIdByName: (value) =>
      id = (site for site in window.model.currentCollection().allSites() when site.name is value)[0]?.id
      id

    findSitesByThresholds: (thresholds) =>
      arr = []
      b = false
      
      for site in window.model.currentCollection().sites()
        for key,threshold of thresholds
          if this.operateWithCondition(threshold.conditions(), site)?            
            arr.push site
            b = true

            console.log site.name()+" "+thresholds[key].propertyName()
            thresholds[key].alertedSitesNum(thresholds[key].alertedSitesNum()+1)
            # thresholds[key].alertedSitesNum = if thresholds[key].alertedSitesNum? then thresholds[key].alertedSitesNum + 1 else 1
            # thresholds[key].alertedSitesNum(thresholds[key].alertedSitesNum()+1)     
            break
          else
            b = false

      return thresholds

    operateWithCondition: (conditions, site) =>
      b = true      
      for condition in conditions
        operator = condition.op().code()
        if condition.valueType().code() is 'percentage'
          percentage = (site.properties()[condition.field()] * 100)/site.properties()[condition.compareField()]
          compareField = percentage
        else
          compareField = site.properties()[condition.field()]

        switch operator
          when "eq","eqi"
            if compareField is condition.value()
              site
            else
              b = false
          when "gt"
            if compareField > condition.value()
              site
            else
              b = false   
          when "lt"
            if compareField < condition.value()
              site
            else
              b = false
          when "con"
            if compareField.indexOf(condition.value()) != -1
              site
            else
              b = false                   
          else
            null

        if b == false
          return null

      # console.log '**********************************'
      # if condition.valueType().code() is 'percentage'
      #   console.log site.name()
      #   console.log percentage
      # console.log '---------------------------------'

      return site


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
        @refineFields.sort (f1, f2) ->
          lowerF1 = f1.name.toLowerCase()
          lowerF2 = f2.name.toLowerCase()
          if lowerF1 == lowerF2 then 0 else (if lowerF1 > lowerF2 then 1 else -1)
        callback() if callback && typeof(callback) == 'function'

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

