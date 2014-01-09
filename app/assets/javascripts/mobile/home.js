//= require mobile/collections/on_mobile_collections
//= require mobile/collections/collection
function initialize(){
  var cachedSites, collectionSchema, i, id;
  onMobileCollections(function() {
    var cachedSites, i, id,
      _this = this;
    if ($('#mobile-collections-main').length > 0) {
      ({
        removeFromSitesCache: function(id) {
          cachedSites = JSON.parse(window.localStorage.getItem("cachedSites"));
          i = 0;
          while (i < cachedSites) {
            if (id = cachedSites[i]["id"]) {
              console.log("DELETE ID" + id);
              delete cachedSites[i];
              break;
            }
          }
          return window.localStorage.setItem("cachedSites", JSON.stringify(cachedSites));
        }
      });    
    }
  });

  if (window.navigator.onLine) {
    $.ajax({
      url: "/mobile/collections.json",
      dataType: "text",
      success: function(collections) {
        var collectionSchema;
        window.localStorage.setItem("collectionSchema", collections);
        window.collectionSchema = window.JSON.parse(window.localStorage.getItem("collectionSchema"));
        Collection.prototype.addDataToCollectionList(window.collectionSchema)
      }
    });
    cachedSites = JSON.parse(window.localStorage.getItem("cachedSites"));
    if (cachedSites) {
      i = 0;
      while (i < cachedSites.length) {
        id = cachedSites[i]["id"];
        $.post(cachedSites[i]["endpoint"], cachedSites[i]["data"], function() {
          var sites;
          sites = JSON.parse(window.localStorage.getItem("cachedSites"));
          i = 0;
          while (i < sites.length) {
            if (id = sites[i]["id"]) {
              sites.splice(i, 1);
              break;
            }
          }
          return window.localStorage.setItem("cachedSites", JSON.stringify(sites));
        });
        i++;
      }
    }
  }
  else {
    window.collectionSchema = window.JSON.parse(window.localStorage.getItem("collectionSchema"));
    Collection.prototype.addDataToCollectionList(window.collectionSchema);
  }
}