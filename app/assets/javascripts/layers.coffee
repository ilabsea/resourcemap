#= require layers/on_layers
#= require_tree ./layers/.

# We do the check again so tests don't trigger this initialization
onLayers -> if $('#layers-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  $('#layer_upload').live 'change', ->
    $('#import_layer_form').submit()

  $.get "/collections/#{collectionId}/layers.json", {}, (layers) =>
  	$.get "/collections/#{collectionId}.json", {}, (collection) ->
	    isVisibleName = collection.is_visible_name
	    isVisibleLocation = collection.is_visible_location
	    window.model = new MainViewModel(collectionId, layers, isVisibleName, isVisibleLocation)
	    ko.applyBindings window.model

	    $('.hidden-until-loaded').show()
