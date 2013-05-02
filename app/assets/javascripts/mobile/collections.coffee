#= require mobile/collections/on_mobile_collections
#= require mobile/collections/main_view_model
#= require mobile/collections/collection
#= require mobile/collections/collections_view_model
onMobileCollections -> if $('#mobile-collections-main').length > 0
  $.get "collections.json", {}, (collections) =>
    window.model = new MainViewModel(collections)

    ko.applyBindings window.model

