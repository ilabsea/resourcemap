onCollections ->

  class @Filter
    isDateFilter: => false
    isLocationMissingFilter: => false

  class @FilterMaybeEmpty extends Filter
    setQueryParams: (options, api = false, condition_id) =>
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
    constructor: (condition_id) ->
      @condition_id = condition_id
    setQueryParams: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id].updated_since = 'last_hour'

    description: => window.t('javascripts.collections.updated_within_the_last_hour')

  class @FilterByLastDay extends FilterByDate
    constructor: (condition_id) ->
      @condition_id = condition_id
    setQueryParams: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id].updated_since = 'last_day'

    description: => window.t('javascripts.collections.updated_within_the_last_day')

  class @FilterByLastWeek extends FilterByDate
    constructor: (condition_id) ->
      @condition_id = condition_id
    setQueryParams: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id].updated_since = 'last_week'

    description: => window.t('javascripts.collections.updated_within_the_last_week')

  class @FilterByLastMonth extends FilterByDate
    constructor: (condition_id) ->
      @condition_id = condition_id
    setQueryParams: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id].updated_since = 'last_month'

    description: => window.t('javascripts.collections.updated_within_the_last_month')

  class @FilterByLocationMissing extends Filter
    constructor: (condition_id) ->
      @condition_id = condition_id

    setQueryParams: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id].location_missing = true

    description: => window.t('javascripts.collections.with_location_missing')

  class @FilterBySiteProperty extends FilterMaybeEmpty
    constructor: (field, operator, name, id, condition_id) ->
      @field = field
      @operator = operator
      @name = name
      @id = id
      @condition_id = condition_id

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id][@field.codeForLink(api)] = "#{@id}"

    descriptionNonEmpty: =>
      window.t('javascripts.collections.where_field_is', {field: @field.name, value: @name})

  class @FilterByTextProperty extends FilterMaybeEmpty
    constructor: (field, operator, value, condition_id) ->
      @field = field
      @operator = operator
      @value = value
      @condition_id = condition_id

    setQueryParamsNonEmpty: (options, api = false) =>
      condition_id = @condition_id
      code = @field.codeForLink(api)
      options[condition_id] = {} if not options[condition_id]
      options[condition_id][code] = {} if not options[condition_id][code]
      options[condition_id][code] = "~=#{@value}"

    descriptionNonEmpty: =>
      window.t('javascripts.collections.where_field_starts_with', {field: @field.name, value: @value})

  class @FilterByNumericProperty extends FilterMaybeEmpty
    constructor: (field, operator, value, condition_id) ->
      @field = field
      @operator = operator
      @value = value
      @condition_id = condition_id

    setQueryParamsNonEmpty: (options, api = false) =>
      condition_id = @condition_id
      code = @field.codeForLink(api)
      options[condition_id] = {} if not options[condition_id]
      options[condition_id][code] = {} if not options[condition_id][code]
      options[condition_id][code][@operator] = @value

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
    constructor: (field, value, condition_id) ->
      @field = field
      @value = value
      @condition_id = condition_id

    setQueryParams: (options, api = false) =>
      code = @field.codeForLink(api)
      condition_id = @condition_id
      options[condition_id] = {} if not options[condition_id]
      options[condition_id][code] = if @value == 'yes' then 'yes' else 'no'

    description: =>
      if @value == 'yes'
        window.t('javascripts.collections.is_yes')
      else
        window.t('javascripts.collections.is_no')

  class @FilterByDateProperty extends FilterMaybeEmpty
    constructor: (field, operator, valueFrom, valueTo, condition_id) ->
      @field = field
      @operator = operator
      @valueTo = valueTo
      @valueFrom = valueFrom
      @condition_id = condition_id

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id][@field.codeForLink(api)]  = "=#{@valueFrom},#{@valueTo}"

    descriptionNonEmpty: =>
      window.t('javascripts.collections.where_field_is_between', {field: @field.name, valueFrom: @valueFrom, valueTo: @valueTo})

  class @FilterByHierarchyProperty extends Filter
    constructor: (field, operator, value, valueLabel,condition_id) ->
      @field = field
      @operator = operator
      @value = value
      @valueLabel = valueLabel
      @condition_id = condition_id

    setQueryParams: (options, api = false) =>
      code = @field.codeForLink(api)
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id][code] = {} if not options[@condition_id][code]
      options[@condition_id][code][@operator] = @value

    description: =>
      window.t('javascripts.collections.with_field_operator_value', {field: @field.name, operator: @operator, value: @valueLabel})

  class @FilterBySelectProperty extends Filter
    constructor: (field, value, valueLabel, condition_id) ->
      @field = field
      @value = value
      @valueLabel = valueLabel
      @condition_id = condition_id

    setQueryParams: (options, api = false) =>
      options[@condition_id] = {} if not options[@condition_id]
      options[@condition_id][@field.codeForLink(api)] = @value

    description: =>
      if @valueLabel
        window.t('javascripts.collections.where_field_is', {field: @field.name, value: @valueLabel})
      else
        window.t('javascripts.collections.where_field_no_value', {field: @field.name})