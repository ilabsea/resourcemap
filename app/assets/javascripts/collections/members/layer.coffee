class @Layer
  constructor: (data) ->
    console.log("Layer Class")
    @id = ko.observable data?.id
    @name = ko.observable data?.name
