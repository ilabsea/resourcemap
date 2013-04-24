#= require mobile/sites/field
#= require mobile/sites/layer
#= require mobile/sites/option

onMobileSites ->
  class @MainViewModel
    constructor: ->
      @collectionId = ko.observable()
      @layers = ko.observableArray([])
      @fields = ko.observableArray([])
      @currentSite = ko.observable()
      @sites = ko.observable()

    saveSite: ->
      callback = (data) =>
      @currentSite().copyPropertiesFromCollection()
      @currentSite().post @currentSite().toJSON(), callback

    showField: (kind) =>
      return false  if kind == 'identifier' || kind == 'select_one' || kind == 'date' || kind == 'select_many' || kind == 'site' || kind == 'user'
      true
