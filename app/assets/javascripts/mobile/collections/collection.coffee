onMobileCollections ->
  class @Collection
    constructor: (collection) ->
      @id = collection?.id
      @name = ko.observable collection?.name

