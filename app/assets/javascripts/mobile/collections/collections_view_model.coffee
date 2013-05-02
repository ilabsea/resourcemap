
onMobileCollections ->
  class @CollectionsViewModel
    @constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()

  
    @createSite:(collection) ->
      collection.fetchFields()
      site = new Site(collection, {})
      @newOrEditSite(site)
      @currentCollection(collection)
      #window.location = "/mobile/collections/" + collection.id + "/sites/new"

