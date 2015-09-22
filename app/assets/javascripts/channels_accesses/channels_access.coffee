onChannelsAccesses ->
  class @ChannelsAccess
    constructor: (data) ->
      collectionId = ko.observable data?.collectionId
      userId = ko.observable data?.userId
      channels = ko.observableArray data?.channels
      collectionUI = ko.observable()
      userUI = ko.observable()


      
