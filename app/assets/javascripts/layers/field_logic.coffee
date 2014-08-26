onLayers ->
  class @FieldLogic
  	constructor: (data) ->
	  	@value = ko.observableArray data?.value ? ['yes']
	  	@layer_id = ko.observable data?.layer_id

  	