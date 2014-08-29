onCollections ->
  class @FieldLogic
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @value = ko.observable(data?.value)
      @field_id = ko.observable(data?.field_id)

    toJSON: =>
      id: @id()
      value: @value()
      field_id: @field_id()