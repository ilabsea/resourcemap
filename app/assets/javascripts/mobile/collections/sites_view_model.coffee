onMobileCollections ->
  class @SitesViewModel
    @constructor: ->
      @editingSite = ko.observable()
      @newOrEditSite = ko.observable()
      @showSite = ko.observable()
      @loadingSite = ko.observable()

    @saveSite: (site) ->
      failed = (data) =>
        @newOrEditSite().saveFailed(true)
      @newOrEditSite().copyPropertiesFromCollection(@currentCollection())
      @newOrEditSite().post @newOrEditSite().toJSON(), @saveSiteCallback
    
    @saveSiteCallback: (response) ->
      if(response.status != 201 )
        @newOrEditSite().saveFailed(true)
        @newOrEditSite().errorMessage(response.message)
      else
        @currentCollection(null)
        @newOrEditSite(null)

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()
      hierarchyChanges = []
      @properties({})

      for field in collection.fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        if field.value()
          value = field.value()

          @properties()[field.esCode] = value
        else
          delete @properties()[field.esCode]

      if window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, hierarchyChanges)

    copyPropertiesToCollection: (collection) =>
      collection.fetchFields =>
        collection.clearFieldValues()
        if @properties()
          for field in collection.fields()
            value = @properties()[field.esCode]

            field.value(value)

