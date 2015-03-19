onLayers ->
  class @FieldLogic
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @value = ko.observable(data?.value)
      if data and data.selected_options?
        @selected_options = ko.observableArray $.map(data?.selected_options, (x) -> new FieldLogicValue(x))
      else
        @selected_options = ko.observableArray([])
      @label = ko.observable(data?.label)
      @field_code = ko.observable(data?.field_code)
      @condition_type = ko.observable(data?.condition_type)
      @editing = ko.observable(false)
      # @field_id = ko.computed =>
      #   window.model?.findFieldByCode(@field_code()).id()


    toJSON: =>
      id: @id()
      value: @value()
      selected_options: $.map(@selected_options(), (x) -> x.toJSON())
      label: @label()
      field_id: @field_id()
      condition_type: @condition_type