onMobileCollections ->
  class @Layer
    constructor: (data) ->
      console.log("onMobileCollections")
      @name = data?.name
      @fields = ko.observableArray $.map data.fields, (x) => new Field x
      @expanded = ko.observable true

    toggleExpand: =>
      @expanded !@expanded()

