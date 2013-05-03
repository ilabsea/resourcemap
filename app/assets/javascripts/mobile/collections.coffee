#= require mobile/collections/on_mobile_collections
#= require mobile/collections/main_view_model
#= require mobile/collections/collection
#= require mobile/collections/collections_view_model
onMobileCollections -> if $('#mobile-collections-main').length > 0
	if window.navigator.onLine
		console.log("online")
		$.ajax
			url: "/collections.json"
			dataType: "text"
			success: (collections) ->
				window.localStorage.setItem("collectionSchema", collections)
				collectionSchema = window.JSON.parse(window.localStorage.getItem("collectionSchema"))
				window.model = new MainViewModel(collectionSchema)
				ko.applyBindings window.model
	else
		console.log("offline")
		collections = window.JSON.parse(window.localStorage.getItem("collectionSchema"))
		window.localStorage.getItem("collectionSchema", collections)
		window.model = new MainViewModel(collections)
		ko.applyBindings window.model
