onCollections ->
  class @Location
    constructor: (data) ->
      @code = data?.code
      @name = data?.name
      @latitude = data?.latitude
      @longitude = data?.longitude