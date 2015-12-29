// = require mobile/collections/on_mobile_collections
// = require mobile/collections/collection
// = require mobile/events
// = require mobile/field
// = require mobile/option
// = require mobile/sub_hierarchy

function initialize(locale){
  var cachedSites, collectionSchema, i, id;
  prepareFlushMessage("#flash_message");
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

    Collection.prototype.pushingPendingSites();

    $.ajax({
      url: "/mobile/collections.json?locale=" + locale ,
      dataType: "json",
      success: function(collections) {
        var collectionSchema;
        window.localStorage.setItem("collectionSchema", collections);
        window.collectionSchema = collections;
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
  $('#map-page').hide();   
}

function prepareFlushMessage(id){
  var content = $(id).html();
  if(content.trim() != ""){
    parent = $(id).children()[0];
    if(parent){
      text = parent.children[0].innerHTML;
      showFlushMessage(text);
    }
  }
}

function showFlushMessage(message){
  $.mobile.showPageLoadingMsg( $.mobile.pageLoadErrorMessageTheme, message, true );
    setTimeout( $.mobile.hidePageLoadingMsg, 3000 );
}