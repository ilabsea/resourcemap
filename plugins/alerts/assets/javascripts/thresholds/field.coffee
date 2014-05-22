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

    findOptionById: (optionId) ->
      return option for option in @options() when option.id() == optionId

  class @FieldImpl
    constructor: (field) ->
      @field = field

    getOptions: => []
    getOperators: => [Operator.EQ]

  class @Field_text extends @FieldImpl
    getOperators: =>
      [Operator.EQ, Operator.CON]

  class @Field_numeric extends @FieldImpl
    getOperators: =>
      [Operator.EQ, Operator.LT, Operator.GT]

  class @Field_yes_no extends @FieldImpl
    getOptions: =>
      [new Option({id: true, label: 'Yes'}), new Option({id: false, label: 'No'})]

  class @FieldSelect extends @FieldImpl
    getOptions: =>
      $.map @field.config?.options ? [], (option) -> new Option option

  class @Field_select_one extends @FieldSelect

  class @Field_select_many extends @FieldSelect

  class @Field_hierarchy extends @FieldImpl

  class @Field_date extends @FieldImpl

  class @Field_site extends @FieldImpl

  class @Field_user extends @FieldImpl

  class @Field_email extends @FieldImpl

  class @Field_phone extends @FieldImpl

  class @Field_identifier extends @FieldImpl

