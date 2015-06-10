onLayers ->
  class @Location
    constructor: (data) ->
      @code = ko.observable data?.code
      @name = ko.observable data?.name
      @latitude = ko.observable data?.latitude
      @longitude = ko.observable data?.longitude

    toJSON: =>
      code: @code()
      name: @name()
      latitude: @latitude()
      longitude: @longitude()
