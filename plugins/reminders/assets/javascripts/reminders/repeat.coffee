onReminders ->
  class @Repeat 
    constructor: (data) ->
      @id = ko.observable data?.id
      @_name = ko.observable data?.name
      @name = ko.computed => window.t('javascripts.plugins.reminders.repeats.' + @_name())
      @order = ko.observable data?.order

    toJSON: =>
      id: @id()
      name: @_name()
      order: @order()
