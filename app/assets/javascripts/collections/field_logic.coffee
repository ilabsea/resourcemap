onCollections ->
  class @FieldLogic
    constructor: (data) ->
      @id = data?.id
      @value = data?.value
      @label = data?.label
      @field_id = data?.field_id
      @field_code = data?.field_code
      if data and data.selected_options?
        @selected_options = $.map(data?.selected_options, (x) -> new FieldLogicValue(x))
      else
        @selected_options = []
      @condition_type = data?.condition_type || "all"