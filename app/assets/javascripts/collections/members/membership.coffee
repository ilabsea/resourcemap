class @Membership extends Expandable
  constructor: (root, data) ->
    _self = @
    @root = root

    # Defined this before callModuleConstructors because it's used by MembershipLayout
    @userId = ko.observable data?.user_id
    @userDisplayName = ko.observable data?.user_display_name
    if data.user_phone_number
      @userPhoneNumber = ko.observable('('+data?.user_phone_number+')')
    else
      @userPhoneNumber = ""
    @admin = ko.observable data?.admin
    @can_view_other = ko.observable data?.can_view_other ? false
    @can_edit_other = ko.observable data?.can_edit_other ? false
    @collectionId = ko.observable root.collectionId()

    rootLayers = data?.layers ? []
    @layers = ko.observableArray $.map(root.layers(), (x) => new LayerMembership(x, rootLayers, _self))

    @sitesWithCustomPermissions = ko.observableArray SiteCustomPermission.arrayFromJson(data?.sites, @)
    @callModuleConstructors(arguments)
    super

    all = (permitted) ->
      _.all _self.layers(), (l) => permitted l

    some = (permitted) ->
      (_.some _self.layers(), (l) => permitted l) and not all permitted

    none = (permitted) ->
      not _.any _self.layers(), (l) => permitted l

    summarize = (permitted) ->
      return window.t('javascripts.collections.members.permissions.all') if all permitted
      return window.t('javascripts.collections.members.permissions.some') if some permitted
      return '' if none permitted

    nonePermission = (l) => not @admin() and not l.read() and not l.write()
    readPermission = (l) => not @admin() and l.read() and not l.write()
    writePermission = (l) => @admin() or l.write()

    @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
    @isCurrentUser = ko.computed => window.userId == @userId()

    @admin.subscribe (newValue) =>
      if newValue == true
        @can_edit_other(newValue)
      $.post "/collections/#{root.collectionId()}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_admin.json"

    @can_view_other.subscribe (newValue) =>
      if newValue == false
        @can_edit_other(false)
        @allLayersNone(true)
      else
        # only update the layer to read when the user click on view_other_site
        if @can_edit_other() == false
          @allLayersRead(true)
      $.post "/collections/#{root.collectionId()}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_can_view_other.json"

    @can_edit_other.subscribe (newValue) =>

      if newValue == true
        @can_view_other(true)
        @allLayersUpdate(true)
      else
        if @can_view_other() == true
          @allLayersRead(true)
      $.post "/collections/#{root.collectionId()}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_can_edit_other.json"

    @someLayersNone = ko.computed => some nonePermission

    @allLayersNone = ko.computed
      read: =>
        return 'all' if all nonePermission
        ''
      write: (val) =>
        return unless val

        _self = @
        _.each @layers(), (layer) ->
          layer.read false
          layer.write false
          $.post "/collections/#{root.collectionId()}/memberships/#{_self.userId()}/set_layer_access.json", { layer_id: layer.layerId(), verb: 'read', access: false}


    @allLayersRead = ko.computed
      read: => return 'all' if all readPermission; ''
      write: (val) =>
        return unless val

        _self = @
        _.each @layers(), (layer) ->
          layer.read true
          layer.write false
          $.post "/collections/#{root.collectionId()}/memberships/#{_self.userId()}/set_layer_access.json", { layer_id: layer.layerId(), verb: 'read', access: true}


    @allLayersUpdate = ko.computed
      read: => return 'all' if all writePermission; ''
      write: (val) =>
        return unless val

        _self = @
        _.each @layers(), (layer) ->
          layer.write true
          layer.read true
          $.post "/collections/#{root.collectionId()}/memberships/#{_self.userId()}/set_layer_access.json", { layer_id: layer.layerId(), verb: 'write', access: true}

    @isNotAdmin = ko.computed => not @admin()

    @summaryNone = ko.computed => summarize nonePermission
    @summaryRead = ko.computed => summarize readPermission
    @summaryUpdate = ko.computed => summarize writePermission
    @summaryAdmin = ko.computed => ''

    @site_permissions_title = ko.computed =>
      if @sitesWithCustomPermissions().length == 0
        window.t('javascripts.collections.members.custom_permissions_for_sites')
      else if @sitesWithCustomPermissions().length == 1
        window.t('javascripts.collections.members.custom_permissions_1_site')
      else
        window.t("javascripts.collections.members.custom_permissions_for_#{@sitesWithCustomPermissions().length}_sites ")

    @customPermissionsAutocompleteId = ko.computed => "autocomplete_#{@userId()}"

    #Setup autocomplete to add custom permissions per site
    $custom_permissions_autocomplete = $("##{@customPermissionsAutocompleteId()} #custom_site_permission")

    @searchSitesUrl = ko.observable "/collections/#{@collectionId()}/sites_by_term.json"

    @customSite = ko.observable ''

    @confirming = ko.observable false

    @createCustomPermissionForSite = () =>
      if $.trim(@customSite()).length > 0
        # TODO: filter results so that they don't include already added sites.
        # Until we do that, we'll just ignore attempts to create duplicates... :(
        return if SiteCustomPermission.findBySiteName(@sitesWithCustomPermissions(), @customSite())?

        $.get "#{@searchSitesUrl()}?term=#{@customSite()}", { term: @customSite() }, (data) ->
          # Check that a site with that name exists
          _.each data, (s) ->
            if s.name == _self.customSite()
              new_permission = new SiteCustomPermission(s.id, s.name, true, true, _self)
              _self.sitesWithCustomPermissions.push new_permission
              _self.customSite ""
              _self.saveCustomSitePermissions()


    @removeCustomPermission = (site_permission) =>
      @sitesWithCustomPermissions.remove site_permission
      @saveCustomSitePermissions()

    @defaultLayerPermissionsExpanded = ko.observable true

    @defaultLayerPermissionsArrow = (base_uri) =>
      if @defaultLayerPermissionsExpanded()
        "#{base_uri}/theme/images/icons/misc/black/arrowDown.png"
      else
        "#{base_uri}/theme/images/icons/misc/black/arrowRight.png"

  toggleDefaultLayerPermissions: =>
    @defaultLayerPermissionsExpanded(not @defaultLayerPermissionsExpanded())

  open_confirm: =>
    @confirming true

  close_confirm: =>
    @confirming false

  confirm: =>
    $.post "/collections/#{@collectionId()}/memberships/#{@userId()}.json", {_method: 'delete'}, =>
      @root.memberships.remove @

  findLayerMembership: (layer) =>
    lm = @layers().filter((x) -> x.layerId() == layer.id())
    if lm.length > 0 then lm[0] else null

  keyPress: (field, event) =>
    switch event.keyCode
      when 13
        @createCustomPermissionForSite()
      when 27 then @exit()
      else true

  saveCustomSitePermissions: =>
    window.sitesCustom = @sitesWithCustomPermissions()
    $.post "/collections/#{@collectionId()}/sites_permission", sites_permission: user_id: @userId(), none: SiteCustomPermission.summarizeNone(@sitesWithCustomPermissions()) , read: SiteCustomPermission.summarizeRead(@sitesWithCustomPermissions()), write: SiteCustomPermission.summarizeWrite(@sitesWithCustomPermissions())

  save: =>
  exit: =>

  updatdNonePermission: (permission) =>
    for layer_permission in @layers()
      layer_permission.noneChecked(permission)
      $.post "/collections/#{@collectionId()}/memberships/#{@userId()}/set_layer_access.json", { layer_id: layer_permission.layerId(), verb: 'read', access: false}
    for site_permission in @sitesWithCustomPermissions()
      site_permission.no_rights(true)
      site_permission.can_read(false)
      site_permission.can_write(false)
      @saveCustomSitePermissions()

  updateReadPermission: (permission) =>
    for layer_permission in @layers()
      layer_permission.read(permission)
      layer_permission.write(false)
      $.post "/collections/#{@collectionId()}/memberships/#{@userId()}/set_layer_access.json", { layer_id: layer_permission.layerId(), verb: 'read', access: true}
    for site_permission in @sitesWithCustomPermissions()
      site_permission.no_rights(false)
      site_permission.can_read(permission)
      site_permission.can_write(false)
      @saveCustomSitePermissions()

  updateWritePermission: (permission) =>
    for layer_permission in @layers()
      layer_permission.write(permission)
      $.post "/collections/#{@collectionId()}/memberships/#{@userId()}/set_layer_access.json", { layer_id: layer_permission.layerId(), verb: 'write', access: true}
    for site_permission in @sitesWithCustomPermissions()
      site_permission.no_rights(false)
      site_permission.can_write(permission)
      @saveCustomSitePermissions()

  disableEdit: =>
    if @admin() || @can_view_other() || @can_edit_other()
      return true
    return false
