#= require thresholds/on_thresholds
#= require_tree

# We do the check again so tests don't trigger this initialization
onThresholds -> if $('#thresholds-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/thresholds/)
  collectionId = parseInt(match[1])

  supportedKinds = ['text', 'numeric', 'yes_no', 'select_one', 'date', 'email', 'phone']

  window.model = new MainViewModel(collectionId)
  ko.applyBindings window.model

  $.get "/collections/#{collectionId}.json", (collection) ->
    window.model.collectionIcon = collection.icon

  $.get "/collections/#{collectionId}/fields.json", (layers) ->
    fields = $.map(layers, (layer) -> layer.fields)
    supportedFields = $.map(fields, (field) -> new Field field if !!~supportedKinds.indexOf field.kind)

    window.model.compareFields supportedFields
    window.model.fields supportedFields

    $.get "/plugin/alerts/collections/#{collectionId}/thresholds.json", (thresholds) ->
      thresholds = $.map thresholds, (threshold) -> new Threshold threshold, window.model.collectionIcon
      window.model.thresholds thresholds
      window.model.isReady(true)
