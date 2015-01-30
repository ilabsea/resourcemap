#= require layers/on_layers
#= require_tree ./layers

# We do the check again so tests don't trigger this initialization
onLayers -> if $('#layers-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  window.collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  $('.location_upload').live 'change', ->
    $('.location_form').submit()
    window.model.startUploadLocation()

  $('#layer_upload').live 'change', ->
    $('#import_layer_form').submit()

  $.get "/collections/#{collectionId}/layers.json", {}, (layers) =>
  	$.get "/collections/#{collectionId}.json", {}, (collection) ->
	    isVisibleName = collection.is_visible_name
	    isVisibleLocation = collection.is_visible_location
	    window.model = new MainViewModel(collectionId, layers, isVisibleName, isVisibleLocation)
	    ko.applyBindings window.model


  #show loading
  $('#loadProgress').show()


  $.get "/collections.json", {}, (collections) =>
    window.collectionList = collections.filter (collection) -> collection.id != parseInt(window.collectionId)
    createBinding()

  $.get "/collections/#{collectionId}/layers/list_layers.json", {}, (layers) =>
    window.layerList = layers
    createBinding()

  window.collectionList = null
  window.layerList = null
  window.bindingCreated = false

  createBinding = ->
    if window.collectionList && window.layerList && !window.bindingCreated
      window.model = new MainViewModel(window.collectionId, window.layerList)
      ko.applyBindings window.model
      window.bindingCreated = true

      $('.hidden-until-loaded').show()
      $('#loadProgress').hide() #hide loading
