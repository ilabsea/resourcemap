onCollections ->

  class @Filter
    isDateFilter: => false
    isLocationMissingFilter: => false

  class @FilterMaybeEmpty extends Filter
    setQueryParams: (options, api = false) =>
      if @operator == 'empty'
        options[@field.codeForLink(api)] = "="
      else
        @setQueryParamsNonEmpty(options, api)

    description: =>
      if @operator == 'empty'
        window.t('javascripts.collections.where_field_no_value', {field: @field.name})
      else
        @descriptionNonEmpty()

  class @FilterByDate
    isDateFilter: => true

  class @FilterByLastHour extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_hour'

    description: => window.t('javascripts.collections.updated_within_the_last_hour')

  class @FilterByLastDay extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_day'

    description: => window.t('javascripts.collections.updated_within_the_last_day')

  class @FilterByLastWeek extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_week'

    description: => window.t('javascripts.collections.updated_within_the_last_week')

  class @FilterByLastMonth extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_month'

    description: => window.t('javascripts.collections.updated_within_the_last_month')

  class @FilterByLocationMissing extends Filter
    setQueryParams: (options, api = false) =>
      options.location_missing = true

    description: => window.t('javascripts.collections.with_location_missing')

  class @FilterBySiteProperty extends FilterMaybeEmpty
    constructor: (field, operator, name, id) ->
      @field = field
      @operator = operator
      @name = name
      @id = id

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@field.codeForLink(api)] = "#{@id}"

    descriptionNonEmpty: =>
      window.t('javascripts.collections.where_field_is', {field: @field.name, value: @name})

  class @FilterByTextProperty extends FilterMaybeEmpty
    constructor: (field, operator, value) ->
      @field = field
      @operator = operator
      @value = value

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@field.codeForLink(api)] = "~=#{@value}"

    descriptionNonEmpty: =>
      window.t('javascripts.collections.where_field_starts_with', {field: @field.name, value: @value})

  class @FilterByNumericProperty extends FilterMaybeEmpty
    constructor: (field, operator, value) ->
      @field = field
      @operator = operator
      @value = value

    setQueryParamsNonEmpty: (options, api = false) =>
      code = @field.codeForLink(api)
      options[code] = {} if not options[code]
      options[code][@operator] = @value

    descriptionNonEmpty: =>
      str = window.t('javascripts.collections.where_field', {field: @field.name})
      switch @operator
        when '=' then str += window.t('javascripts.collections.equals')
        when '<' then str += window.t('javascripts.collections.is_less_than')
        when '<=' then str += window.t('javascripts.collections.is_less_than_or_equal_to')
        when '>' then str += window.t('javascripts.collections.is_greater_than')
        when '>=' then str += window.t('is_greater_than_or_equal_to')
      str += "#{@value}"

  class @FilterByYesNoProperty extends Filter
    constructor: (field, value) ->
      @field = field
      @value = value

    setQueryParams: (options, api = false) =>
      code = @field.codeForLink(api)
      options[code] = if @value == 'yes' then 'yes' else 'no'

    description: =>
      if @value == 'yes'
        window.t('javascripts.collections.is_yes')
      else
        window.t('javascripts.collections.is_no')

  class @FilterByDateProperty extends FilterMaybeEmpty
    constructor: (field, operator, valueFrom, valueTo) ->
      @field = field
      @operator = operator
      @valueTo = valueTo
      @valueFrom = valueFrom

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@field.codeForLink(api)]  = "=#{@valueFrom},#{@valueTo}"

    descriptionNonEmpty: =>
      window.t('javascripts.collections.where_field_is_between', {field: @field.name, valueFrom: @valueFrom, valueTo: @valueTo})

  class @FilterByHierarchyProperty extends Filter
    constructor: (field, operator, value, valueLabel) ->
      @field = field
      @operator = operator
      @value = value
      @valueLabel = valueLabel

    setQueryParams: (options, api = false) =>
      code = @field.codeForLink(api)
      options[code] = {} if not options[code]
      options[code][@operator] = @value

    description: =>
      window.t('javascripts.collections.with_field_operator_value', {field: @field.name, operator: @operator, value: @valueLabel})

  class @FilterBySelectProperty extends Filter
    constructor: (field, value, valueLabel) ->
      @field = field
      @value = value
      @valueLabel = valueLabel

    setQueryParams: (options, api = false) =>
      options[@field.codeForLink(api)] = @value

    description: =>
      if @valueLabel
        window.t('javascripts.collections.where_field_is', {field: @field.name, value: @valueLabel})
      else
        window.t('javascripts.collections.where_field_no_value', {field: @field.name})
