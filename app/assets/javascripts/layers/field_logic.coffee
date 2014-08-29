onLayers ->
  class @FieldLogic
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @value = ko.observable(data?.value)
      @layer_id = ko.observable(data?.layer_id)

    toJSON: =>
      id: @id()
      value: @value()
      layer_id: @layer_id()