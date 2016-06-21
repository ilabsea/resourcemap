onCollections ->

  # A Layer field
  class @Field
    constructor: (data) ->
      @esCode = "#{data.id}"
      @code = data.code
      @name = data.name
      @kind = data.kind
      @is_mandatory = ko.observable data?.is_mandatory ? false
      @is_enable_field_logic = data.is_enable_field_logic
      @photo = ''
      @preKeyCode = null
      @photoPath = '/photo_field/'
      @showInGroupBy = @kind in ['select_one', 'select_many', 'hierarchy']
      @writeable = @originalWriteable = data?.writeable
      @allowsDecimals = ko.observable data?.config?.allows_decimals == 'true'
      @value = ko.observable()
      @value.subscribe =>
        if @skippedState() == false && @kind in ["yes_no", "select_one", "select_many", "numeric"]
          @setFieldFocus()
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
        @keyType = if @allowsDecimals() then 'decimal' else 'integer'
        @range = if data.config?.range?.minimum? || data.config?.range?.maximum?
                  data.config?.range

      if @kind in ['numeric', 'yes_no', 'select_one', 'select_many']
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
        @resultLocations = ko.observableArray([])
        @filterText = ko.observable('')

        @resultLocationsUI =  ko.observableArray([])
        @offset = 0
        @limit = 3
        @showLocations = ko.observable(false)
        @maximumSearchLength = data.config?.maximumSearchLength
        @remainingLocations = ko.computed =>
          remaining = if @value()
            location = @findLocationName(@value())
            @filterText(location.name) if location
            @resultLocationsUI().filter((x) => @value()?.indexOf(x.id) == -1 && x.name.toLowerCase().indexOf(@filterText().toLowerCase()) != -1)
          else
            @resultLocationsUI().filter((x) => x.name.toLowerCase().indexOf(@filterText().toLowerCase()) != -1)
          #sort the result by name
          remaining.sort (a, b) =>
            return -1 if a.name < b.name
            return 1  if a.name > b.name
            return 0
          remaining

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
      @skippedState = ko.observable(false)
      @errorClass = ko.computed => if @error() then 'error' else '' # For field number

      @is_blocked_by = ko.observableArray([])
      @blocked = ko.computed =>
        field_object = @get_dom_object(this)
        if @is_blocked_by() != undefined and @is_blocked_by().length > 0
          field_object.block({message: ""})
        else
          field_object.unblock()

    refresh_skip: =>
      if(@is_blocked_by())
        tmp = @is_blocked_by()
        @is_blocked_by(tmp)

    setFieldFocus: =>
      if window.model.newOrEditSite()
        if @kind == 'yes_no'
          value = if @value() then 1 else 0
        else if @kind == 'numeric' || @kind == 'select_one' || @kind == 'select_many'
          value = @value()
        else
          return
        noSkipField = false
        if @field_logics.length > 0 && @skippedState() == false
          for field_logic in @field_logics
            b = false
            if field_logic.field_id?
              if @kind == 'yes_no' || @kind == 'select_one'
                if value == field_logic.value
                  console.log 'value field_logic : ', value
                  @setFocusStyleByField(field_logic.field_id)
                  return
                else
                  noSkipField = true

              if @kind == 'numeric' && value != ''
                if field_logic.condition_type == '<'
                  if parseFloat(value) < field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return
                  else
                    @enableSkippedField(@esCode)

                if field_logic.condition_type == '<='
                  if parseFloat(value) <= field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return
                  else
                    @enableSkippedField(@esCode)

                if field_logic.condition_type == '='
                  if parseFloat(value) == field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return
                  else
                    @enableSkippedField(@esCode)

                if field_logic.condition_type == '>'
                  if parseFloat(value) > field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return
                  else
                    @enableSkippedField(@esCode)

                if field_logic.condition_type == '>='
                  if parseFloat(value) >= field_logic.value
                    @setFocusStyleByField(field_logic.field_id)
                    return
                  else
                    @enableSkippedField(@esCode)

              if @kind == 'select_many'
                if field_logic.condition_type == 'any'
                  if value?
                    for field_value in value
                      for field_logic_value in field_logic.selected_options
                        if field_value == parseInt(field_logic_value.value)
                          b = true
                          @setFocusStyleByField(field_logic.field_id)
                          return
                        else
                          @enableSkippedField(@esCode) if @value() != null

                if field_logic.condition_type == 'all'
                  tmp = []
                  if value?
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
                  else
                    @enableSkippedField(@esCode) if @value() != null

          if @value() != "" && @value() != null && noSkipField
            @enableSkippedField(@esCode)
            return

    setFocusStyleByField: (field_id) =>
      field = window.model.newOrEditSite().findFieldByEsCode(field_id)
      if typeof field != 'undefined'
        @disableSkippedField(@esCode, field_id)
        console.log 'window.model.newOrEditSite : ', window.model.newOrEditSite().scrollable()
        if window.model.newOrEditSite().scrollable() == true
          @removeFocusStyle()
          if field.kind == "select_one"
            $('#select_one-input-'+field.code).focus()
          else if field.kind == "select_many"
            field.expanded(true)
            $('#select-many-input-'+field.code).focus()
          else if field.kind == "hierarchy"
            console.log '$(hierearchy): '
            $('#'+field.esCode)[0].scrollIntoView(true)
            console.log '$(skjf k): ', $('#' + field.esCode)
            $('#'+field.esCode).focus()
          else if field.kind == "yes_no"
            $('#yes_no-input-'+field.code).focus()
          else if field.kind == "photo"
            $('#'+field.code).focus()
          else if field.kind == "date"
            $('#'+field.kind+'-input-'+field.esCode)[0].scrollIntoView(true)
            $('#'+field.kind+'-input-'+field.esCode).focus()
          else
            $('#'+field.kind+'-input-'+field.code).focus()
      else
        @enableSkippedField(@esCode, field_id)

    enableSkippedField: (field_id) =>
      layers = window.model.currentCollection().layers()
      flag = false
      $.map(window.model.editingSite().fields(), (f) =>
        if f.esCode == field_id
          flag = true
          return
        if flag
          @enableField f
      )

    disableSkippedField: (from_field_id, to_field_id) =>
      layers = window.model.currentCollection().layers()
      flag = false
      after_skip = false
      $.map(window.model.editingSite().fields(), (f) =>
        if f.esCode == from_field_id
          flag = true
          after_skip = true
          return true
        if f.esCode == to_field_id
          flag = false
        if flag
          @disableField f, from_field_id
        else
          if after_skip
            @enableField f
      )

    disableField: (field, by_field_id) =>
      field.is_mandatory(false)
      field.skippedState(true)
      field.is_blocked_by([])
      unless field.is_mandatory()
        index = field.is_blocked_by().indexOf(by_field_id)
        if(index < 0 )
          tmp = field.is_blocked_by()
          tmp.push(by_field_id) if by_field_id != undefined
        field.value(null)
        field_object = @get_dom_object(field)
        field.is_blocked_by(tmp)
        # field_object.block({message: ""})

    get_dom_object: (field) =>
      switch field.kind
        when 'select_one'
          # field.value("")
          field_id = field.kind + "-input-" + field.code
          field_object = $("#" + field_id).parent()
        when 'select_many'
          if field.expanded()
            field_id = "select-many-input-" + field.code
            field_object = $("#" + field_id).parent().parent()
          else
            field.expanded(true)
            field_id = "select-many-input-" + field.code
            field_object = $("#" + field_id).parent().parent()
            field.expanded(false)

        when 'hierarchy'
          field_id = field.esCode
          field_object = $("#" + field_id).parent()
        when 'date'
          field_id = "date-input-" + field.esCode
          field_object = $("#" + field_id).parent()
        when 'photo'
          field_id = field.code
          field_object = $("#" + field_id).parent()
        else
          field_id = field.kind + "-input-" + field.code
          field_object = $("#" + field_id).parent()
      field_object

    enableField: (field) =>
      field.is_mandatory(field.originalIsMandatory)
      field.skippedState(false)
      switch field.kind
        when 'select_many'
          if field.expanded()
           field_id = "select-many-input-" + field.code
          else
           field_id = "select-many-" + field.code
          field_object = $("#" + field_id).parent()
        when 'hierarchy'
          field_id = field.esCode
          field_object = $("#" + field_id).parent()
        when 'date'
          field_id = "date-input-" + field.esCode
          field_object = $("#" + field_id).parent()
        when 'photo'
          field_id = field.code
          field_object = $("#" + field_id).parent()
        else
          field_id = field.kind + "-input-" + field.code
          field_object = $("#" + field_id).parent()
      field.is_blocked_by([])

    setValueFromSite: (value) =>
      if @kind == 'date' && $.trim(value).length > 0
        # Value from server comes with utc time zone and creating a date here gives one
        # with the client's (browser) time zone, so we convert it back to utc
        date = new Date(value)
        date.setTime(date.getTime() + date.getTimezoneOffset() * 60000)
        value = @datePickerFormat(date)
      else if @kind == 'numeric' || @kind == 'calculation'
        value = @valueUIFor(value)

      value = '' if (value == null && value == '')

      @value(value)

    enableScrollFocusView: =>
      console.log 'lalalas'
      if @field_logics.length > 0
        if @value() == ""
          @enableSkippedField @esCode
        else
          console.log 'here'
          window.model.newOrEditSite().scrollable(true)

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
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else if @kind == 'site'
        name = window.model.currentCollection()?.findSiteNameById(value)
        if value && name then name else ''
      # else if @kind == 'location'
        # location = @findLocationName(value)
        # if location then location.name else ''
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
        window.model.initControlKey()
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
          if parseFloat(@value()) >= parseFloat(@range.minimum) && parseFloat(@value()) <= parseFloat(@range.maximum)
            @errorMessage('')
          else
            @errorMessage('Invalid value, value must be in the range of ('+@range.minimum+'-'+@range.maximum+")")
        else
          if @range.maximum
            if parseFloat(@value()) <= parseFloat(@range.maximum)
              @errorMessage('')
            else
              @errorMessage('Invalid value, value must be less than or equal '+@range.maximum)
            return

          if @range.minimum
            if parseFloat(@value()) >= parseFloat(@range.minimum)
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

    validate_digit: (keyCode) =>
      value = $('#'+@kind+'-input-'+@code).val()
      #check digit precision
      valueAfterSplit = value.split '.'
      if valueAfterSplit.length >= 2
        decimalValue = valueAfterSplit[1]
        ele = document.getElementById(@kind+"-input-"+@code)
        pos = $.caretPosition(ele)
        if @digitsPrecision
          if keyCode == 8 || keyCode == 9 || keyCode == 173 || (keyCode >= 37 && keyCode <=40)
            return true
          if pos <= value.indexOf('.')
            return true
          if decimalValue.length < parseInt(@digitsPrecision)
            return true
          if decimalValue.length >= parseInt(@digitsPrecision)
            return false

      return true

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else
          if field.kind == "numeric"
            if field.allowsDecimals()
              return @validate_digit(event.keyCode)
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

    loadMoreLocations: =>
      @showLocations(true)
      startIndex = (@offset * @limit)+@offset
      endIndex = startIndex + @limit
      @offset = @offset + 1
      @resultLocationsUI(@resultLocationsUI().concat(@resultLocations()[startIndex..endIndex]))

    selectLocation: (location) =>
      @showLocations(false)
      @filterText(location.name)
      @value(location.code)

    filterLocation: (model, event) =>
      switch event.keyCode
        when 13 # Enter
          for location, i in @remainingLocations()
            if location.selected()
              @selectLocation(location)
              break
          false
        when 38 # Up
          for location, i in @remainingLocations()
            if location.selected() && i > 0
              location.selected(false)
              @remainingLocations()[i - 1].selected(true)
              break
          false
        when 40 # Down
          for location, i in @remainingLocations()
            if location.selected() && i != @remainingLocations().length - 1
              location.selected(false)
              @remainingLocations()[i + 1].selected(true)
              break
          false
        when 8
          @value('')
          true
        else
          true
    findLocationName: (code) =>
      for location in @resultLocations()
        return location if location.code == code
