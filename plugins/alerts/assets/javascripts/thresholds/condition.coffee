#= require thresholds/value_type
#= require thresholds/operator

onThresholds ->
  class @Condition
    constructor: (data) ->
      @field = ko.observable window.model.findField data?.field
      @compareField = ko.observable window.model.findField data?.compare_field ? data?.field # assign data.field only when data.compare_field doesn't exist to prevent error on view
      @op = ko.observable Operator.findByCode data?.op
      @kind = ko.observable data?.kind
      @value = ko.observable data?.value
      @valueLabel = ko.observable data?.valueLabel
      @valueType = ko.observable ValueType.findByCode data?.type ? 'value'
      @valueUI = ko.computed
        read: => @field()?.format @value()
        write: (value) => @value value
      @formattedValue = ko.computed =>
        switch @field()?.kind()
          when 'numeric' then "#{@valueType()?.format @value()}"
          when 'hierarchy' then @valueLabel()
          else @valueUI()
      @error = ko.computed => return window.t('javascripts.plugins.alerts.errors.value_is_invalid') unless @field()?.valid @value()
      @valid = ko.computed => not @error()?

      @field.subscribe =>
        @op Operator.EQ
        @compareField null
        @valueType ValueType.VALUE
        @valueLabel null
        @value null

      if typeof @kind() == 'function' && @kind()() == 'hierarchy'
        @buildFieldHierarchy()

    buildFieldHierarchy: =>
      @field().value(@value())
      @field().valueLabel(@valueLabel())
      @hierarchy = @field().config.hierarchy
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@field(), x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: window.t('javascripts.collections.fields.no_value')})   

    toJSON: =>
      field: @field().esCode()
      op: @op().code()
      value: @field()?.encode @value()
      valueLabel: @field().valueLabel()
      type: @valueType().code()
      compare_field: @compareField()?.esCode()
      kind: @field().kind
