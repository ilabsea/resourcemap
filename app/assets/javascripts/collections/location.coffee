onCollections ->
  class @Location
    constructor: (data) ->
      @code = data?.code
      @name = data?.name
      @label = data?.name
      @id = data?.code
      @latitude = data?.latitude
      @longitude = data?.longitude