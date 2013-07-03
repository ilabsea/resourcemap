#= require module
#= require mobile/collections/site
#= require mobile/collections/layer
#= require mobile/collections/field
#= require mobile/collections/collections_view_model
#= require mobile/collections/sites_view_model
onMobileCollections ->
  class @MainViewModel extends Module
    @include CollectionsViewModel
    @include SitesViewModel
    constructor: (collections) ->
      @initialize(collections)

    initialize: (collections) ->
      @callModuleConstructors(arguments)
      # We make sure all the methods in this model are correctly bound to "this".
      # Using Module and @include makes the methods in the included class not bound
      # to this, and they don't work when being invoked by knockout when interacting
      # with the view.
      @[k] = v.bind(@) for k, v of @ when v.bind? && !ko.isObservable(v)
  
    exitSite: ->
      @currentCollection(null)
      @newOrEditSite(null)
      window.history.back()


