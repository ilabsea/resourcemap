#= require collections/thresholds/value_type
#= require collections/thresholds/operator

onCollections ->
  class @Condition
    constructor: (data) ->
      @field = ko.observable data?.field
      @compareField = ko.observable data?.compare_field ? data?.field # assign data.field only when data.compare_field doesn't exist to prevent error on view
      @op = ko.observable Operator.findByCode data?.op
      @value = ko.observable data?.value
      @valueType = ko.observable ValueType.findByCode data?.type ? 'value'
      # @valueUI = ko.computed
      #   read: => @field()?.format? @value()
      #   write: (value) => @value value
      # @formattedValue = ko.computed =>
      #   switch @field()?.kind()?
      #     when 'numeric' then "#{@valueType()?.format @value()}"
      #     else @valueUI()
      @error = ko.computed => return "value is invalid" unless @field()?.valid? @value()
      @valid = ko.computed => not @error()?

      @field.subscribe =>
        @op Operator.EQ
        @compareField null
        @valueType ValueType.VALUE
        @value null

    toJSON: =>
      field: @field().esCode()
      op: @op().code()
      value: @field()?.encode @value()
      type: @valueType().code()
      compare_field: @compareField()?.esCode()
