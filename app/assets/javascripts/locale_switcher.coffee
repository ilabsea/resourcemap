@changeLocale = (locale) ->
  query = $.url().param()
  window.location.search = $.param query if query.locale = locale

$ ->
  $("#locale-switcher a").on 'click', ->
    window.changeLocale $(@).data 'locale'