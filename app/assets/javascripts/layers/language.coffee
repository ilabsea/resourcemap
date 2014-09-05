onLayers ->
  class @Language
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @code = ko.observable(data?.code)
      @name = ko.observable(data?.name)