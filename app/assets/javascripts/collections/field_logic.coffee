onCollections ->
  class @FieldLogic
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @value = ko.observable(data?.value)
      @label = ko.observable(data?.label)
      @field_id = ko.observableArray([data?.field_id])

    toJSON: =>
      id: @id()
      value: @value()
      label: @label()
      field_id: @field_id()