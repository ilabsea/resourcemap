onChannelsAccesses ->
  class @MainViewModel
    constructor: ()->
      @userEmail = ko.observable()
      @collectionId = ko.observable()
      # @collections = ko.observableArray()

    #   @collectionValueUI =  ko.computed
    #     read: =>  @valueUIFor(@collectionId())
    #     write: (value) =>
    #      @value(@valueUIFrom(value))


    # valueUIFor: (value) =>      
    #   name = @findCollectionNameById(value)
    #   if value && name then name else ''

    # findCollectionNameById: (value) =>
    #   allSites = window.model.currentCollection().allSites()
    #   return if not allSites
    #   (site.name for site in allSites when site.id is parseInt(value))[0]

    initAutocomplete: (callback) ->
      console.log $(".autocomplete-collection-input")
      if $(".autocomplete-collection-input").length > 0 && $(".autocomplete-collection-input").data("autocomplete")
        $(".autocomplete-collection-input").data("autocomplete")._renderItem = (ul, item) ->
           $("<li></li>").data("item.autocomplete", item).append("<a>" + item.name+" created by "+ item.users[0].email+ "</a>").appendTo ul

    # collectionValueUI: () ->



    # constructor: ()->
    #   @channelsAccesses = ko.observableArray()
    #   @userValue = ko.observable()
    #   @collectionValue = ko.observable()
    #   @channels = ko.observableArray()
    #   @currentChannelsAccess = ko.observable()

    # addChannelsAccess: =>
    #   channels = new ChannelsAccess
    #   @currentChannelsAccess channels
    #   @channelsAccesses.push channels

    # saveChannelAccess: ->

    # saveChannelAccessCallback: (data) =>
    #   if data.errors
    #     @currentGateway().serverError(data.errors.join(';'))
    #   else
    #     @currentGateway().id = data.id
    #     @currentGateway().serverError(null)
    #     @currentGateway null

    # searchUsersUrl: -> "/channels_accesses/search_user.json"
    searchCollectionsUrl: -> "/channels_accesses/search_collection.json"