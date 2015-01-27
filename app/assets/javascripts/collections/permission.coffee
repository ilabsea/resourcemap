onCollections ->

  class @Permission
    constructor: (data) ->
      @allSites = true

      @someSites = data?.some_sites.map (x) -> parseInt x.id

    canAccess: (siteId) ->
      @allSites or @someSites.indexOf(siteId) > -1
