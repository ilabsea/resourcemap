onMobileCollections ->
  class @Collection
    constructor: (collection) ->
      @id = collection?.id
      @name = ko.observable collection?.name
      @layers = ko.observableArray $.map collection.layers, (layer) -> new Layer layer
      @fields = ko.observableArray([])


    fetchFields: =>
      fields = []
      for layer in @layers()
        for field in layer.fields()
          field.value(null)
          fields.push(field)
      @fields(fields)
