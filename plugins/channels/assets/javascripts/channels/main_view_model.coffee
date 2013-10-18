onChannels ->
  class @MainViewModel
    constructor: (@collectionId)->
      @gateways         = ko.observableArray()
      @selectedGateways = ko.observableArray()
      @update_success 	= ko.observable("")
      @collectionId     = ko.observable collectionId 
    
    saveChannel: =>
      $.post "/collections/#{@collectionId()}/register_gateways.json", gateways: @selectedGateways(), @saveChannelCallback

    saveChannelCallback: (data) =>
    	@update_success("Successfully updated gateways")
