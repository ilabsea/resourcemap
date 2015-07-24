#= require module
#= require collections/sites_container

onCollections ->

  # Used when enable view as hierarchy mode
  class @HierarchySite extends Module
    @include SitesContainer

    constructor: (data, level = 0) ->
      @constructorSitesContainer()
      @id = data?.id
      @selectedSiteFid = data?.field_id
      @selectedSiteFValue = data?.field_value
      @name = data?.name
      @site = data?.site
      @level = level
      @expanded = ko.observable(false)
      @selected = ko.observable(false)
      @selectedHierarchy = ko.observable()

      @selectedSiteChildren = ko.observableArray()
      @selectedSiteParent = ko.observable()
      
      @hierarchySites = if data.sub?
                          $.map data.sub, (x) => new HierarchySite(x, level + 1)
                        else
                          []



      @selectedHierarchy.subscribe (newValue) =>
        #make the hierarchy selected or highlighted
        if model.selectedHierarchyMode()
          model.selectedHierarchyMode().selected(false)
        @selected(true)
        model.selectedHierarchyMode(newValue)
        
        @toggleExpand()

      # Styles
      @labelStyle = @style()['labelStyle']
      @columnStyle = @style()['columnStyle']

    sitesUrl: =>
      console.log @queryParams()
      # "/collections/#{window.model.currentCollection().id}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      selected_site_children: @selectedSiteChildren(@toArray(@hierarchySites, []))
      selected_site_parent: @selectedSiteParent()
      selected_site_fId: @selectedSiteFid
      selected_site_fValue: @selectedSiteFValue

    toArray: (hierarchySites, siteIds)=>
      for hs in hierarchySites
        siteIds.push(hs.id)
        @toArray(hs.hierarchySites, siteIds)
      siteIds

    unselect: =>
      @selected(false)

    toggleExpand: =>
      @expanded(!@expanded())
      window.model.reloadMapSites()
      
    # private
    style: =>
      pixels_per_indent_level = 20
      row_width = 270

      indent = @level * pixels_per_indent_level

      {
        columnStyle: {
          height: '30px',
          cursor: 'pointer'
        }
        labelStyle: {
          width: "#{row_width - 28 - indent}px",
          marginLeft: "#{6 + indent}px",
          paddingLeft: '2px',
          marginTop: '1px'
        }
      }