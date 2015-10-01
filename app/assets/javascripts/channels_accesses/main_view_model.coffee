onChannelsAccesses ->
  class @MainViewModel
    constructor: ()->
      @collectionId = ko.observable()
      @collectionName = ko.observable()
      @collections = ko.observableArray()
      @isFocus = ko.observable(false)
      @isFocus.subscribe => 
        $(".autocomplete-collection-input").is(':focus')
        console.log @isFocus()

      @collectionValueUI =  ko.computed
        read: =>  @valueUIFor(@collectionId())
        write: (value) =>
          console.log 'value ; ', value
          @collectionId(@valueUIFrom(value))

    valueUIFor: (value) =>      
      name = @findCollectionNameById(value)
      console.log 'name : ', name
      if value && name then name else ''


    findCollectionNameById: (value) =>
      collections = @collections()
      return if not collections
      (collection.name for collection in collections when collection.id is parseInt(value))[0]

    findCollectionIdByName: (value) =>
      id = (collection for collection in @collections() when collection.name is value)[0]?.id
      console.log '@collections ; ', @collections()
      console.log 'id : ', id
      id

    valueUIFrom: (value) =>
      @findCollectionIdByName(value) || ""

    setCollections: =>
      $.get "/channels_accesses/search_collection.json", (collections) =>
        @collections(collections)

    initAutocomplete: (callback) ->
      if $(".autocomplete-collection-input").length > 0 && $(".autocomplete-collection-input").data("autocomplete")
        $(".autocomplete-collection-input").data("autocomplete")._renderItem = (ul, item) ->
           $("<li></li>").data("item.autocomplete", item).append("<a>" + item.name+" created by "+ item.users[0].email+ "</a>").appendTo ul

    searchCollectionsUrl: -> "/channels_accesses/search_collection.json"

