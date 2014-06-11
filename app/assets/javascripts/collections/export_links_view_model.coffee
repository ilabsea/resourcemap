onCollections ->

  class @ExportLinksViewModel
    @exportInRSS: ->
      $.get "/get_user_auth_token", {}, (auth_token) =>
        window.open @currentCollection().link('rss', auth_token)
    @exportInSHP: -> window.open @currentCollection().link('shp')
    @exportInJSON: -> 
      $.get "/get_user_auth_token", {}, (auth_token) =>
        window.open @currentCollection().link('json', auth_token)
    @exportInKML: -> 
      $.get "/get_user_auth_token", {}, (auth_token) =>
        window.open @currentCollection().link('kml', auth_token)
    @exportInCSV: -> 
      $.get "/get_user_auth_token", {}, (auth_token) =>
        window.open @currentCollection().link('csv', auth_token)
