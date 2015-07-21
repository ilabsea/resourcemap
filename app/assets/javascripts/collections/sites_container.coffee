#= require module
#= require collections/site

onCollections ->

  class @SitesContainer 

    @constructorSitesContainer: ->
      @expanded = ko.observable false
      @sites = ko.observableArray()
      @sitesPage = 1
      @hasMoreSites = ko.observable true
      @loadingSites = ko.observable true
      @siteIds = {}
      @hierarchySites = ko.observableArray()

    # Loads SITES_PER_PAGE sites more from the server, it there are more sites.
    @loadMoreSites: ->
      return unless @hasMoreSites()
      @loadingSites true
      # Fetch more sites. We fetch one more to know if we have more pages, but we discard that
      # extra element so the user always sees SITES_PER_PAGE elements.
      $.get @sitesUrl(), {offset: (@sitesPage - 1) * SITES_PER_PAGE, limit: SITES_PER_PAGE + 1, _alert: window.model.showingAlert() if window.model.showingAlert()}, (data) =>
        @sitesPage += 1
        if data.length == SITES_PER_PAGE + 1
          data.pop()
        else
          @hasMoreSites false
        for site in data
          @addSite @createSite(site)
        @loadingSites false
        window.model.refreshTimeago()
        
        if @hierarchy_mode
          @prepareSitesAsHierarchy()

    @prepareSitesAsHierarchy: ->
      fi = @field_identify
      fp = @field_parent
      items = []
      for site in @sites()
        property = site.properties()
        if property[fp] == undefined
          items.push({id: site.id(), name: site.name(), site: site, parent_id: ""})
        else 
          for s, i in @sites()
            p = s.properties()
            if property[fp].toString() == p[fi] && p[fi] != undefined
              items.push({id: site.id(), name: site.name(), site: site, parent_id: s.id()}) 
              break
            else 
              if i == @sites().length-1
                items.push({id: site.id(), name: site.name(), site: site, parent_id: ""})
      #make the items array to be hierarchy
      hierarchy = @getHierarchySite(items, "")
      @hierarchySites($.map hierarchy, (x) => new HierarchySite(x))


    @getHierarchySite: (items, parent_id) ->
      out = []
      for i of items
        if items[i].parent_id == parent_id
          sub = @getHierarchySite(items, items[i].id)
          if sub.length
            items[i].sub = sub
          out.push items[i]
      out

    @reloadSites: ->
      @loadingSites true
      @siteIds = {}
      @sites = ko.observableArray()
      $.get @sitesUrl(), {offset: 0, limit: (@sitesPage - 1) * SITES_PER_PAGE, _alert: window.model.showingAlert() if window.model.showingAlert()}, (data) =>
        for site in data
          @addSite @createSite(site)
        @loadingSites false
        window.model.refreshTimeago()
        if @hierarchy_mode
          @prepareSitesAsHierarchy()

    @addSite: (site, isNew = false) ->
      return @siteIds[site.id()] if @siteIds[site.id()]

      # This check is because the selected site might be selected on the map,
      # but not in the tree. So we use that one instead of the one from the server,
      # and set its collection to ourself.
      if window.model.selectedSite()?.id() == site.id()
        window.model.selectedSite(site)
        site = window.model.selectedSite()
      else
        site = window.model.siteIds[site.id()] if window.model.siteIds[site.id()]

      @sites.push(site)

      window.model.siteIds[site.id()] = site
      @siteIds[site.id()] = site

      site

    @removeSite: (site) ->
      @sites.remove site
      delete window.model.siteIds[site.id()]
      delete @siteIds[site.id()]

    @toggleExpand: ->
      # Load more sites when we expand, but only the first time
      if !@expanded() && @hasMoreSites() && @sitesPage == 1
        @loadMoreSites()


      # Toggle select folder
      if !@expanded()
        window.model.selectHierarchy(this)
      else
        window.model.selectHierarchy(null)

      @expanded(!@expanded())
      window.model.reloadMapSites()

    @createSite: (site) -> new Site(@, site)
