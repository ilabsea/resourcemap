onMobileCollections ->
	class @Collection
		constructor: (collection) ->
			@id = collection?.id
			@name = ko.observable collection?.name
			console.log(collection.layers)
			layers = []
			for layer in collection.layers 
				layerObj = new Layer(layer)
				layers.push layerObj 
				console.log(layerObj)
			@layers = ko.observableArray(layers)
			console.log(@layers())
			@fields = ko.observableArray([])


		fetchFields: =>
			fields = []
			for layer in @layers()
				for field in layer.fields()
					field.value(null)
					fields.push(field)
					@fields(fields)


