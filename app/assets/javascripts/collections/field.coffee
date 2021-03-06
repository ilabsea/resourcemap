onCollections ->

  # A Layer field
  class @Field
    constructor: (data) ->
      @esCode = "#{data.id}"
      @code = data.code
      @name = data.name
      @kind = data.kind
      @is_mandatory = data.is_mandatory 

      @is_enable_field_logic = data.is_enable_field_logic

      @photo = '' 
      @preKeyCode = null
      @photoPath = '/photo_field/'
      @showInGroupBy = @kind in ['select_one', 'select_many', 'hierarchy']
      @writeable = @originalWriteable = data?.writeable
      
      @allowsDecimals = ko.observable data?.config?.allows_decimals == 'true'
      @value = ko.observable()
      
      @value.subscribe => @setFieldFocus()

      @hasValue = ko.computed =>
        if @kind == 'yes_no'
          true
        else
          @value() && (if @kind == 'select_many' then @value().length > 0 else @value())

      @valueUI =  ko.computed
       read: =>  @valueUIFor(@value())
       write: (value) =>
        @value(@valueUIFrom(value))

      if @kind == 'numeric'
        @digitsPrecision = data?.config?.digits_precision
        @range = if data.config?.range?.minimum? || data.config?.range?.maximum?
                  data.config?.range
        @field_logics = if data.config?.field_logics?
                          $.map data.config.field_logics, (x) => new FieldLogic x
                        else
                          []

      if @kind in ['yes_no', 'select_one', 'select_many']
        @field_logics = if data.config?.field_logics?
                          $.map data.config.field_logics, (x) => new FieldLogic x
                        else
                          []


      if @kind in ['select_one', 'select_many']
        @options = if data.config?.options?
                    $.map data.config.options, (x) => new Option x
                  else
                    []
        @optionsIds = $.map @options, (x) => x.id

        # Add the 'no value' option
        @optionsIds.unshift('')
        @optionsUI = [new Option {id: '', label: window.t('javascripts.collections.fields.no_value') }].concat(@options)
        @optionsUIIds = $.map @optionsUI, (x) => x.id

        @hierarchy = @options

      if @kind == 'location'
        @locations = if data.config?.locations?
                      $.map data.config.locations, (x) => new Location x
                     else
                      []
        @resultLocations = ko.observableArray []

        @maximumSearchLength = data.config?.maximumSearchLength
        

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
            @options.filter((x) => x.label.toLowerCase().indexOf(@filter().toLowerCase()) == 0)
          remaining[0].selected(true) if remaining.length > 0
          remaining
      else
        @filter = ->

      @editing = ko.observable false
      @expanded = ko.observable false # For select_many
      @errorMessage = ko.observable()
      @error = ko.computed => !!@errorMessage()
     
    setFieldFocus: =>
      if window.model.newOrEditSite() 
        if @kind == 'yes_no'
          value = if @value() then 1 else 0
        else if @kind == 'numeric' || @kind == 'select_one' || @kind == 'select_many'
          value = @value()
        else
          return
        
        if @field_logics
          for field_logic in @field_logics
            b = false
            if field_logic.field_id?
              if @kind == 'yes_no' || @kind == 'select_one'
                if value == field_logic.value
                  @setFocusStyleByField(field_logic.field_id)
                  return
              if @kind == 'numeric'
                if field_logic.condition_type == '<'
                  if parseInt(value) < field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return
                if field_logic.condition_type == '<='
                  if parseInt(value) <= field_logic.value
                    @setFocusStyleByField(field_logic.field_id)  
                    return         
                if field_logic.condition_type == '='
                  if parseInt(value) == field_logic.value
                    @setFocusStyleByField(field_logic.field_id)  
                    return        
                if field_logic.condition_type == '>'
                  if parseInt(value) > field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return            
                if field_logic.condition_type == '>='
                  if parseInt(value) >= field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return

              if @kind == 'select_many'
                if field_logic.condition_type == 'any'
                  for field_value in value
                    for field_logic_value in field_logic.selected_options
                      if field_value == parseInt(field_logic_value.value)
                        b = true
                        @setFocusStyleByField(field_logic.field_id)
                        return

                if field_logic.condition_type == 'all'
                  tmp = []
                  for field_value in value             
                    for field_logic_value in field_logic.selected_options
                      if field_value == parseInt(field_logic_value.value)                        
                        b = true
                        field_id = field_logic.field_id
                        tmp.push field_value
                      else
                        b = false
                  if tmp.length == field_logic.selected_options.length
                    @setFocusStyleByField(field_id)
                    return

    setFocusStyleByField: (field_id) =>
      field = window.model.newOrEditSite().findFieldByEsCode(field_id)
      @removeFocusStyle()
      if field.kind == "select_one"
        $('#select-one-input-'+field.code).focus()  
      else if field.kind == "select_many"
        field.expanded(true)
        $('#select-many-input-'+field.code).focus()
      else if field.kind == "hierarchy"  
        $('#'+field.esCode)[0].scrollIntoView(true) 
        $('#'+field.esCode).focus() 
      else if field.kind == "yes_no"
        $('#yes-no-input-'+field.code).focus()
      else if field.kind == "photo"
        $('#'+field.code).focus()
      else if field.kind == "date"
        $('#'+field.kind+'-input-'+field.esCode)[0].scrollIntoView(true)
        $('#'+field.kind+'-input-'+field.esCode).focus()
      else
        $('#'+field.kind+'-input-'+field.code).focus() 

    setValueFromSite: (value) =>
      if @kind == 'date' && $.trim(value).length > 0
        # Value from server comes with utc time zone and creating a date here gives one
        # with the client's (browser) time zone, so we convert it back to utc
        date = new Date(value)
        date.setTime(date.getTime() + date.getTimezoneOffset() * 60000)
        value = @datePickerFormat(date)

      value = '' unless value

      @value(value)

    setDefaultValueToYesNoField: =>
      @value(false)

    removeFocusStyle: =>
      $('div').removeClass('focus')
      $('input:not(#name)').removeClass('focus')
      $('select').removeClass('focus')
      $('select').blur()
      $('input').blur()

    codeForLink: (api = false) =>
      if api then @code else @esCode

    # The value of the UI.
    # If it's a select one or many, we need to get the label from the option code.
    valueUIFor: (value) =>
      if @kind == 'yes_no'
        if value
          value = window.t('javascripts.collections.fields.yes')
        else 
          if @writeable
            value = window.t('javascripts.collections.fields.no')
          else
            value = ''
            if window.model.showSite()
              value = window.t('javascripts.collections.fields.no')        
      else if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'location'
        if value then @labelForLocation(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else if @kind == 'site'
        name = window.model.currentCollection()?.findSiteNameById(value)
        if value && name then name else ''

      else
        if value then value else ''

    valueUIFrom: (value) =>
      if @kind == 'site'
        # Return site_id or "" if the id for this name is not found (deleting the value or invalid value)
        window.model.currentCollection()?.findSiteIdByName(value) || ""
      else
        value

    datePickerFormat: (date) =>
      date.getMonth() + 1 + '/' + date.getDate() + '/' + date.getFullYear()

    buildHierarchyItems: =>
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: window.t('javascripts.collections.fields.no_value')})

    edit: =>
      @editing(true)
      if !window.model.currentCollection()?.currentSnapshot
        @originalValue = @value()

        # For select many, if it's an array we need to duplicate it
        if @kind == 'select_many' && typeof(@) == 'object'
          @originalValue = @originalValue.slice(0)

        @editing(true)
        optionsDatePicker = {}
        optionsDatePicker.onSelect = (dateText) =>
          @valueUI(dateText)
          @save()
        optionsDatePicker.onClose = () =>
          @save()
        window.model.initDatePicker(optionsDatePicker)
        window.model.initAutocomplete()
        $('textarea').autogrow()

    validateRangeAndDigitsPrecision: =>
      @validateRange()
      @validateDigitsPrecision()

    validateDigitsPrecision: =>
      if @digitsPrecision
        @value(parseInt(@value() * Math.pow(10, parseInt(@digitsPrecision))) / Math.pow(10, parseInt(@digitsPrecision)))

    validateRange: =>
      if @range
        if @range.minimum && @range.maximum
          if parseInt(@value()) >= parseInt(@range.minimum) && parseInt(@value()) <= parseInt(@range.maximum)
            @errorMessage('')
          else
            @errorMessage('Invalid value, value must be in the range of ('+@range.minimum+'-'+@range.maximum+")")
        else
          if @range.maximum
            if parseInt(@value()) <= parseInt(@range.maximum)
              @errorMessage('')
            else
              @errorMessage('Invalid value, value must be less than or equal '+@range.maximum)
            return
          
          if @range.minimum
            if parseInt(@value()) >= parseInt(@range.minimum)
              @errorMessage('')
            else
              @errorMessage('Invalid value, value must be greater than or equal '+@range.minimum)
            return      

    validate_integer_only: (keyCode) =>
      value = $('#'+@kind+'-input-'+@code).val()
      if value == null || value == ""
        if(keyCode == 189 || keyCode == 173) && (@preKeyCode != 189 || @preKeyCode == null || @preKeyCode == 173) #allow '-' for both chrome & firefox
          @preKeyCode = keyCode
          return true
      else
        if(keyCode == 189 || keyCode == 173) && value.charAt(0) != '-'
          @preKeyCode = keyCode
          return true
      if keyCode > 31 && (keyCode < 48 || keyCode > 57) && (keyCode != 8 && keyCode != 46) && keyCode != 37 && keyCode != 39  #allow right and left arrow key
        return false
      else 
        @preKeyCode = keyCode
        return true

    validate_decimal_only: (keyCode) =>
      value = $('#'+@kind+'-input-'+@code).val()
      if (value == null || value == "")&& (keyCode == 229 || keyCode == 190) #prevent dot at the beginning
        return false
      if (keyCode != 8 && keyCode != 46 && keyCode != 173) && (keyCode != 190 || value.indexOf('.') != -1) && (keyCode < 48 || keyCode > 57) #prevent multiple dot
        return false
      else
        return true

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else
          if field.kind == "numeric"
            if field.allowsDecimals()
              return @validate_decimal_only(event.keyCode)
            else
              return @validate_integer_only(event.keyCode)
          return true   

    exit: =>
      @value(@originalValue)
      @editing(false)
      @filter('')
      delete @originalValue

    save: =>
      window.model.editingSite().updateProperty(@esCode, @value())
      if !@error()
        @editing(false)
        @filter('')
        delete @originalValue

    closeDatePickerAndSave: =>
      if $('#ui-datepicker-div:visible').length == 0
        @save()

    selectOption: (option) =>
      @value([]) unless @value()
      @value().push(option.id)
      @value.valueHasMutated()
      @filter('')

    removeOption: (optionId) =>
      @value([]) unless @value()
      @value(arrayDiff(@value(), [optionId]))
      @value.valueHasMutated()

    expand: => @expanded(true)

    filterKeyDown: (model, event) =>
      switch event.keyCode
        when 13 # Enter
          for option, i in @remainingOptions()
            if option.selected()
              @selectOption(option)
              break
          false
        when 38 # Up
          for option, i in @remainingOptions()
            if option.selected() && i > 0
              option.selected(false)
              @remainingOptions()[i - 1].selected(true)
              break
          false
        when 40 # Down
          for option, i in @remainingOptions()
            if option.selected() && i != @remainingOptions().length - 1
              option.selected(false)
              @remainingOptions()[i + 1].selected(true)
              break
          false
        else
          true

    labelFor: (id) =>
      for option in @optionsUI
        if option.id == id
          return option.label
      null

    labelForLocation: (code) =>
      for option in @resultLocations()
        if option.code == code
          return option.name
      null

    # In the table view, use a fixed size width for each property column,
    # which depends on the length of the name.
    suggestedWidth: =>
      if @name.length < 10
        '100px'
      else
        "#{20 + @name.length * 8}px"

    isPluginKind: => -1 isnt PLUGIN_FIELDS.indexOf @kind

    exitEditing: ->
      @editing(false)
      @writeable = @originalWriteable

    fileSelected: (data, event) =>
      fileUploads = $("#" + data.code)[0].files
      if fileUploads.length >0

        photoExt = fileUploads[0].name.split('.').pop()

        value = (new Date()).getTime() + "." + photoExt
        @value(value)
        
        reader = new FileReader()
        reader.onload = (event) =>
          @photo = event.target.result.split(',')[1]
          $("#imgUpload-" + @code).attr('src',event.target.result)
          $("#divUpload-" + @code).show()
          
        reader.readAsDataURL(fileUploads[0])
      else
        @photo = ''
        @value('')

    removeImage: =>
      @photo = ''
      @value('')
      $("#" + @code).attr("value",'')
      $("#divUpload-" + @code).hide()
  





