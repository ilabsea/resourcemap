onLayers ->
  class @Field
    constructor: (layer, data) ->
      @layer = ko.observable layer
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @code = ko.observable data?.code
      @kind = ko.observable data?.kind
      
      @is_enable_field_logic = ko.observable data?.is_enable_field_logic ? false


      @config = data?.config
      @field_logics_attributes = data?.field_logics_attributes
      @metadata = data?.metadata
      @is_mandatory = data?.is_mandatory
      

      @kind_titleize = ko.computed =>
        (@kind().split(/_/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      @ord = ko.observable data?.ord

      @hasFocus = ko.observable(false)
      @isNew = ko.computed =>  !@id()?

      @fieldErrorDescription = ko.computed => if @hasName() then "'#{@name()}'" else "number #{@layer().fields().indexOf(@) + 1}"

      # Tried doing "@impl = ko.computed" but updates were triggering too often
      @impl = ko.observable eval("new Field_#{@kind()}(_this)")
      @kind.subscribe => @impl eval("new Field_#{@kind()}(_this)")

      @nameError = ko.computed => if @hasName() then null else "the field #{@fieldErrorDescription()} is missing a Name"
      @codeError = ko.computed =>
        if !@hasCode() then return "the field #{@fieldErrorDescription()} is missing a Code"
        if (@code() in ['lat', 'long', 'name', 'resmap-id', 'last updated']) then return "the field #{@fieldErrorDescription()} code is reserved"
        null
        
      @error = ko.computed => @nameError() || @codeError() || @impl().error()
      @valid = ko.computed => !@error()

    hasName: => $.trim(@name()).length > 0

    hasCode: => $.trim(@code()).length > 0

    selectingLayerClick: =>
      @switchMoveToLayerElements true

    selectingLayerSelect: =>
      return unless @selecting

      if window.model.currentLayer() != @layer()
        $("a[id='#{@name()}']").html("Move to layer '#{@layer().name()}' upon save")
      else
        $("a[id='#{@name()}']").html('Move to layer...')
      @switchMoveToLayerElements false

    switchMoveToLayerElements: (v) =>
      $("a##{@name()}").toggle()
      $("select[id='#{@name()}']").toggle()
      @selecting = v

    buttonClass: =>
      FIELD_TYPES[@kind()].css_class

    iconClass: =>
      FIELD_TYPES[@kind()].small_css_class

    toJSON: =>
      @code(@code().trim())
      json =
        id: @id()
        name: @name()
        code: @code()
        kind: @kind()
        ord: @ord()
        layer_id: @layer().id()
        is_mandatory: @is_mandatory
        is_enable_field_logic: @is_enable_field_logic
      @impl().toJSON(json)
      json

  class @FieldImpl
    constructor: (field) ->
      @field = field
      @error = -> null

    toJSON: (json) =>

  class @Field_text extends @FieldImpl
    constructor: (field) ->
      super(field)
      @attributes = if field.metadata?
                      ko.observableArray($.map(field.metadata, (x) -> new Attribute(x)))
                    else
                      ko.observableArray()
      @advancedExpanded = ko.observable false

    toggleAdvancedExpanded: =>
      @advancedExpanded(not @advancedExpanded())

    addAttribute: (attribute) =>
      @attributes.push attribute

    toJSON: (json) =>
      json.metadata = $.map(@attributes(), (x) -> x.toJSON())

  class @Field_numeric extends @FieldImpl
    constructor: (field) ->
      super(field)

      @allowsDecimals = ko.observable field?.config?.allows_decimals == 'true'

    toJSON: (json) =>
      json.config = {allows_decimals: @allowsDecimals()}

  class @Field_yes_no extends @FieldImpl
    constructor: (field) ->
      super(field)

      @field_logics = if field.config?.field_logics?
                        ko.observableArray(
                          $.map(field.config.field_logics, (x) ->
                            if field.config.field_logics.length == 1
                              if x.value == 'yes'
                                field_logic_no = new FieldLogic
                                field_logic_no.id(2)
                                field_logic_no.value('no')

                                return [new FieldLogic(x),field_logic_no]
                              if x.value == 'no'
                                field_logic_yes = new FieldLogic
                                field_logic_yes.id(1)
                                field_logic_yes.value('yes')

                                return [field_logic_yes, new FieldLogic(x)]

                            if field.config.field_logics.length == 2
                              new FieldLogic(x)
                          ))
                     else
                        field_logic_yes = new FieldLogic
                        field_logic_yes.id(1)
                        field_logic_yes.value('yes')

                        field_logic_no = new FieldLogic
                        field_logic_no.id(2)
                        field_logic_no.value('no')     

                        ko.observableArray([field_logic_yes, field_logic_no])

      @nextId = field.config?.next_id || @field_logics().length + 1


    addFieldLogic: (field_logic) =>
      @field_logics.push field_logic
      @nextId += 1

    validFieldLogic: (field_logic) =>
      @field_logics().filter (field_logic) -> typeof field_logic.layer_id() isnt 'undefined'

    toJSON: (json) =>
      # valid_logic = @validFieldLogic(@field_logics())
      json.config = {field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}
      # json.field_logics_attributes = $.map(@field_logics(), (x) -> x.toJSON())

  class @FieldSelect extends @FieldImpl
    constructor: (field) ->
      super(field)
      @options = if field.config?.options?
                   ko.observableArray($.map(field.config.options, (x) -> new Option(x)))
                 else
                   ko.observableArray()
      @nextId = field.config?.next_id || @options().length + 1
      @error = ko.computed =>
        if @options().length > 0
          codes = []
          labels = []
          for option in @options()
            return "duplicated option code '#{option.code()}' for field #{@field.name()}" if codes.indexOf(option.code()) >= 0
            return "duplicated option label '#{option.label()}' for field #{@field.name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          "the field '#{@field.name()}' must have at least one option"

    addOption: (option) =>
      option.id @nextId
      @options.push option
      @nextId += 1

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId}

  class @Field_select_one extends @FieldSelect
    constructor: (field) ->
      super(field)

  class @Field_select_many extends @FieldSelect
    constructor: (field) ->
      super(field)

  class @Field_hierarchy extends @FieldImpl
    constructor: (field) ->
      super(field)
      @hierarchy = ko.observable field.config?.hierarchy
      @uploadingHierarchy = ko.observable(false)
      @errorUploadingHierarchy = ko.observable(false)
      @initHierarchyItems() if @hierarchy()
      @error = ko.computed =>
        if @hierarchy() && @hierarchy().length > 0
          null
        else
          "the field #{@field.fieldErrorDescription()} is missing the Hierarchy"

    setHierarchy: (hierarchy) =>
      @hierarchy(hierarchy)
      @initHierarchyItems()
      @uploadingHierarchy(false)
      @errorUploadingHierarchy(false)

    initHierarchyItems: =>
      @hierarchyItems = ko.observableArray $.map(@hierarchy(), (x) -> new HierarchyItem(x))

    toJSON: (json) =>
      json.config = {hierarchy: @hierarchy()}

  class @Field_date extends @FieldImpl

  class @Field_site extends @FieldImpl

  class @Field_user extends @FieldImpl

  class @Field_photo extends @FieldImpl
