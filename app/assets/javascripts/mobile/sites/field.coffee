onMobileSites ->
  class @Field
    constructor: (data) ->
      @esCode = "#{data.id}"
      @code = ko.observable data.code
      @name = data.name
      @kind = data.kind
      @showInGroupBy = @kind in ['select_one', 'select_many', 'hierarchy']
      #@writeable = @originalWriteable = data?.writeable

      @allowsDecimals = ko.observable data?.config?.allows_decimals == 'true'

      @value = ko.observable()
      @hasValue = ko.computed =>
        if @kind == 'yes_no'
          true
        else
          @value() && (if @kind == 'select_many' then @value().length > 0 else @value())

      @valueUI =  ko.computed
       read: =>  @valueUIFor(@value())
       write: (value) =>
         @value(@valueUIFrom(value))

      if @kind in ['select_one', 'select_many']
        @options = if data.config?.options?
                    $.map data.config.options, (x) => new Option x
                  else
                    []
        @optionsIds = $.map @options, (x) => x.id
        if @kind == 'select_one'
          @optionsUI = [new Option {id: '', label: '(no value)' }].concat(@options)
          @optionsUIIds = $.map @optionsUI, (x) => x.id
        else
          @optionsUI = @options
        @hierarchy = @options

      if @kind == 'hierarchy'
        @hierarchy = data.config?.hierarchy

      @buildHierarchyItems() if @hierarchy?

      if @kind == 'select_many'
        @filter = ko.observable('') # The text for filtering options in a select_many
        @remainingOptions = ko.computed =>
          option.selected(false) for option in @options
          remaining = if @value()
            @options.filter((x) => @value()?.indexOf(x.id) == -1 && x.label.toLowerCase().indexOf(@filter().toLowerCase()) == 0)
          else
            @options
          remaining[0].selected(true) if remaining.length > 0
          remaining
      else
        @filter = ->

      @editing = ko.observable false
      @expanded = ko.observable false # For select_many
  
    valueUIFor: (value) =>
      if @kind == 'yes_no'
        if value then 'yes' else 'no'
      else if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else if @kind == 'date'
        if value then @datePickerFormat(new Date(value)) else ''
      else if @kind == 'site'
        name = window.model.currentCollection()?.findSiteNameById(value)
        if value && name then name else ''
      else
        if value then value else ''
  
    valueUIFrom: (value) =>
      if @kind == 'date'
        value
      else if @kind == 'site'
        # Return site_id or "" if the id for this name is not found (deleting the value or invalid value)
        window.model.currentCollection()?.findSiteIdByName(value) || ""
      else
        value
