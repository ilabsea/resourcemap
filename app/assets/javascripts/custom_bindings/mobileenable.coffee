ko.bindingHandlers.mobileenable =
  update: (el) ->
    ko.bindingHandlers.enable.update.apply(el, arguments)
    try
      $.fn.button && $(el).button('refresh')
    catch error
