#= require module
#= require collections/sites_container

onCollections ->

  # Used when enable view as hierarchy mode
  class @HierarchySite extends Module
    @include SitesContainer

    constructor: (data, level = 0) ->
      @constructorSitesContainer()
      @id = data?.id
      @name = data?.name
      @site = data?.site
      @level = level
      @expanded = ko.observable(false)
      @selected = ko.observable(false)

      @hierarchySites = if data.sub?
                          $.map data.sub, (x) => new HierarchySite(x, level + 1)
                        else
                          []

      # Styles
      @labelStyle = @style()['labelStyle']
      @columnStyle = @style()['columnStyle']

      @isSelected = ko.computed => @ == window.model.selectedHierarchy()

    toggleExpand: =>
      @expanded(!@expanded())

    # private
    style: =>
      pixels_per_indent_level = 20
      row_width = 280

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


