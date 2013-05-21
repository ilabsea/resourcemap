onMobileCollections ->
	class @Collection
		constructor: (collection) ->
			@id = collection?.id
			@name = ko.observable collection?.name
			layers = []
			for layer in collection.layers 
				layerObj = new Layer(layer)
				layers.push layerObj 
			@layers = ko.observableArray(layers)
			@fields = ko.observableArray([])


		fetchFields: =>
			fields = []
			for layer in @layers()
				for field in layer.fields()
					field.value(null)
					fields.push(field)
					@fields(fields)


