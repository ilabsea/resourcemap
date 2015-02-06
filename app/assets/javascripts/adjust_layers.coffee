#= require layers/on_layers
#= require_tree ./layers/.

# We do the check again so tests don't trigger this initialization
onLayers -> if $('#adjust-layers').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  collectionId = parseInt(match[1])
  $.get "/collections/#{collectionId}/layers.json", {}, (layers) =>
    $.get "/collections/#{collectionId}/layers/pending_layers.json", {}, (pendingLayers) =>
      $.get "/collections/#{collectionId}.json", {}, (collection) ->
        isVisibleName = collection.is_visible_name
        isVisibleLocation = collection.is_visible_location
        allLayers = $.map(layers, (x) -> new Layer(x))
        window.model = new MainViewModel(collectionId, pendingLayers, isVisibleName, isVisibleLocation, true, allLayers)
        # window.model.allLayers = $.map(layers, (x) -> new Layer(x))
        ko.applyBindings window.model
        $('.hidden-until-loaded').show()
