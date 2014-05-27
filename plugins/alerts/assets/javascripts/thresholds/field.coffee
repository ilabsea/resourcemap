#= require thresholds/operator
#= require thresholds/option
onThresholds ->
  class @Field
    constructor: (data) ->
      @esCode = ko.observable "#{data.id}"
      @name = ko.observable data.name
      @code = ko.observable data.code
      @kind = ko.observable data.kind
      @config = data?.config

      @impl = new window["Field_#{@kind()}"](@)

      @options = ko.computed => @impl.getOptions()
      @operators = ko.computed => @impl.getOperators()

    format: (value) ->
      @impl.format value

    findOptionById: (optionId) ->
      return option for option in @options() when option.id() == optionId

  class @FieldImpl
    constructor: (field) ->
      @field = field

    format: (value) -> value
    getOptions: => []
    getOperators: => [Operator.EQ]

  class @Field_text extends @FieldImpl
    getOperators: =>
      [Operator.EQ, Operator.CON]

  class @Field_numeric extends @FieldImpl
    getOperators: =>
      [Operator.EQ, Operator.LT, Operator.GT]

  class @Field_yes_no extends @FieldImpl
    format: (value) ->
      if value then 'Yes' else 'No'

    getOptions: =>
      [new Option({id: true, label: 'Yes'}), new Option({id: false, label: 'No'})]

  class @Field_select_one extends @FieldImpl
    format: (value) ->
      @field.findOptionById(value)?.label()

    getOptions: =>
      $.map @field.config?.options ? [], (option) -> new Option option

  class @Field_date extends @FieldImpl
    format: (value) ->
      value.toDate().strftime '%m/%d/%Y'

    getOperators: =>
      [Operator.EQ, Operator.LT, Operator.GT]

  class @Field_email extends @FieldImpl

  class @Field_phone extends @FieldImpl
