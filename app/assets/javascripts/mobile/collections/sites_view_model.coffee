onMobileCollections ->
  class @SitesViewModel
    @constructor: ->
      @editingSite = ko.observable(false)
      @newOrEditSite = ko.observable(false)
      @showSite = ko.observable(false)
      @loadingSite = ko.observable(false)

    @saveSite: (site) ->
      console.log site

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


