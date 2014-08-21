onLayers ->
  class @FieldLogics
  	constructor: (layer, data) ->
	  	@field = $.map data.field, (x) => new Field x
	  	@value = ko.observable data.value
	  	@layer = $.map data.layer, (x) => new Layer x

  	