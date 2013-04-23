#= require mobile/sites/on_mobile_sites
#= require mobile/sites/main_view_model
#= require mobile/sites/site
onMobileSites -> if $('#mobile-sites-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/sites/)
  collectionId = parseInt(match[1])
  window.model = new MainViewModel()

  $.get "/collections/#{collectionId}/fields", {}, (data) =>
    layers =  $.map(data, (x) => new Layer(x))
    window.model.layers layers

    fields = []
    for layer in window.model.layers()
      for field in layer.fields()
        fields.push(field)
    window.model.fields(fields)
    window.model.collectionId(collectionId)
    window.model.currentSite(new Site)

    ko.applyBindings window.model
