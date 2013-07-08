onMobileCollections ->
	class @Collection
		constructor: (collection) ->
			@id = collection?.id
			@name = ko.observable collection?.name
			@layers = ko.observableArray $.map collection.layers, (layer) -> new Layer layer
			@fields = ko.observableArray $.map @layers(), (layer) -> layer.fields()
