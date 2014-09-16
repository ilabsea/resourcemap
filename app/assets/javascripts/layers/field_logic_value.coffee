onLayers ->
  class @FieldLogicValue
    constructor: (data) ->
      @label = ko.observable(data?.label)
      @value = ko.observable(data?.value)

    toJSON: =>
      value: @value()
      label: @label()
