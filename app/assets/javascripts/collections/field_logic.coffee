onCollections ->
  class @FieldLogic
    constructor: (data) ->
      @id = data?.id
      @value = data?.value
      @label = data?.label
      @field_id = data?.field_id