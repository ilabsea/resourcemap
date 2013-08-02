#= require mobile/collections/on_mobile_collections
#= require mobile/collections/main_view_model
#= require mobile/collections/collection
#= require mobile/collections/collections_view_model
onMobileCollections -> if $('#mobile-collections-main').length > 0

	removeFromSitesCache: (id) => 
		cachedSites = JSON.parse(window.localStorage.getItem("cachedSites"))
		i = 0
		while i < cachedSites
			if id = cachedSites[i]["id"]
				console.log("DELETE ID" + id)
				delete cachedSites[i]
				break
		window.localStorage.setItem("cachedSites", JSON.stringify(cachedSites))

	if window.navigator.onLine
		$.ajax
			url: "/mobile/collections.json"
			dataType: "text"
			success: (collections) ->
				window.localStorage.setItem("collectionSchema", collections)
				collectionSchema = window.JSON.parse(window.localStorage.getItem("collectionSchema"))
				window.model = new MainViewModel(collectionSchema)
				ko.applyBindings window.model
		
		cachedSites = JSON.parse(window.localStorage.getItem("cachedSites"))
		if cachedSites
			i = 0
			while i < cachedSites.length
				id = cachedSites[i]["id"] 
				$.post cachedSites[i]["endpoint"], cachedSites[i]["data"], ->
					sites = JSON.parse(window.localStorage.getItem("cachedSites"))
					i = 0
					while i < sites.length
						if id = sites[i]["id"]
							sites.splice(i, 1)
							break
					window.localStorage.setItem("cachedSites", JSON.stringify(sites))
				i++

	else
		collectionSchema = window.JSON.parse(window.localStorage.getItem("collectionSchema"))
		window.model = new MainViewModel(collectionSchema)
		ko.applyBindings window.model
