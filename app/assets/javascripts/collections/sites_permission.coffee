#= require collections/permission
onCollections ->

  class @SitesPermission
    constructor: (data) ->
      @read = new Permission(data['read'])
      @write = new Permission(data['write'])
      @none = new Permission(data['none'])

    canNone: (site) -> 
      @none.canAccess(site.id())

    canRead: (site) ->
      @read.canAccess(site.id())

    canUpdate: (site) ->
      @write.canAccess(site.id())
