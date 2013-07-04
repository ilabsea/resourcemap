onMobileCollections ->
  class @CollectionsViewModel
    @constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
  
    @createSite:(collection) ->
      site = new Site(collection, {})
      @newOrEditSite(site)
      @currentCollection(collection)
      $.mobile.navigate("#site-page")
      #window.location = "/mobile/collections/" + collection.id + "/sites/new"

