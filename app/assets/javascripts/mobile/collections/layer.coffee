onMobileCollections ->
  class @Layer
    constructor: (data) ->
      @name = data?.name
      @fields = ko.observableArray $.map data.fields, (x) => new Field x
      @expanded = ko.observable true

    toggleExpand: =>
      @expanded !@expanded()
