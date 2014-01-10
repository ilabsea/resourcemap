//= require mobile/events
//= require mobile/field
//= require mobile/option

function Collection (collection) {
  this.id = collection != null ? collection.id : void 0;
  this.name = collection != null ? collection.name : void 0;
  this.layers = collection != null ? collection.layers : void 0;
  this.fields = [];
};

Collection.prototype.pushingPendingSites = function(){
  pendingSites = JSON.parse(window.localStorage.getItem("offlineSites"));
  if(pendingSites != null){
    for(var i=0; i< pendingSites.length; i++){
      Collection.prototype.ajaxCreateSite(pendingSites[i]["collectionId"], pendingSites[i]["formData"]);
    }
    window.localStorage.setItem("offlineSites", JSON.stringify([]));
  }
}

Collection.prototype.fetchFields = function() {
  var fields = [];
  var layers = this.layers();
  for (var i = 0; i < layers.length; i++) {
    layer = layers[i];
    fields = layer.fields();
    for (j = 0; j < fields.length; j++) {
      field = fields[j];
      field.value(null);
      fields.push(field);
    }
  }
  return this.fields(fields);
};

Collection.prototype.createSite = function(id){
  for(var i=0; i< window.collectionSchema.length; i++){
    if(window.collectionSchema[i]["id"] == id){
      Collection.prototype.showFormAddSite(window.collectionSchema[i])
    }
  }
}

Collection.prototype.showFormAddSite = function(schema){
  $("#mobile-collections-main").hide();
  $("#mobile-sites-main").show();
  fieldHtml = Collection.prototype.addLayerForm(schema);
  $("#title").html(schema["name"]);
  $("#fields").html(fieldHtml);
  Collection.prototype.handleFieldUI(schema);
}

Collection.prototype.saveSite = function(){  
  var collectionId = $("#collectionId").val();
  if(Collection.prototype.validateData()){
    // Collection.prototype.fixDateMissingTimeZone(collectionId);
    var formData = new FormData($('form')[0]);
    if(window.navigator.onLine){
      Collection.prototype.ajaxCreateSite(collectionId, formData);
    }
    else{
      Collection.prototype.storeOfflineData(collectionId, formData);
    }
  }
}

Collection.prototype.storeOfflineData = function(collectionId, formData){
  pendingSites = JSON.parse(window.localStorage.getItem("offlineSites"));
  if(pendingSites != null && pendingSites.length > 0){
    pendingSites.push({"collectionId" : collectionId, "formData" : formData});
  }
  else{
    pendingSites = [{"collectionId" : collectionId, "formData" : formData}];
  }
  window.localStorage.setItem("offlineSites", JSON.stringify(pendingSites));
  Collection.prototype.goHome();
  Collection.prototype.showErrorMessage("Successfully store data in offline.");
}

Collection.prototype.ajaxCreateSite = function(collectionId, formData){
  $.ajax({
      url: '/mobile/collections/' + collectionId + '/sites',  //Server script to process data
      type: 'POST',
      success: function(){
        Collection.prototype.goHome();
        Collection.prototype.showErrorMessage("Successfully saved.");
      },
      error: function(data){
        Collection.prototype.showErrorMessage("Save new site failed!");
      },
      data: formData,
      cache: false,
      contentType: false,
      processData: false
  });
}

Collection.prototype.validateData = function(){
  if($("#name").val() == ""){
    Collection.prototype.showErrorMessage("Name can not be empty.");
    return false;
  }
  if($("#lat").val() == ""){
    Collection.prototype.showErrorMessage("Location's latitude can not be empty.");
    return false;
  }
  if($("#lng").val() == ""){
    Collection.prototype.showErrorMessage("Location's longitude can not be empty.");
    return false;
  }
  return true;
}

Collection.prototype.fixDateMissingTimeZone = function(collectionId){
  form = "";
  for(h=0; h<window.collectionSchema.length;h++){
    schema = window.collectionSchema[h];
    if(schema.id == collectionId){
      for(i=0; i<schema["layers"].length;i++){
        form = form + '<div><h5>' + schema["layers"][i]["name"] + '</h5>';
        for(j=0; j<schema["layers"][i]["fields"].length; j++){
          var field = schema["layers"][i]["fields"][j];
          if(field.kind == 'date' && $("#" + field.code).val() != ""){
            Collection.prototype.modifyDate(field.code);
          }
        }
        form = form + "</div>";
      }
    }
  }
  return form;
}

Collection.prototype.modifyDate = function(code){
  origin = $("#" + code).val();
  newDate = origin + "T00:00:00Z" ;
  $("#" + code).val(newDate);
  return true;
}

Collection.prototype.showErrorMessage = function(text){
  $.mobile.showPageLoadingMsg( $.mobile.pageLoadErrorMessageTheme, text, true );
  // hide after delay
  setTimeout( $.mobile.hidePageLoadingMsg, 1500 );
}

Collection.prototype.progressHandlingFunction =function(e){
    if(e.lengthComputable){
        $('progress').attr({value:e.loaded,max:e.total});
    }
}

Collection.prototype.addLayerForm = function(schema){
  form = "";
  for(i=0; i<schema["layers"].length;i++){
    form = form + '<div><h5>' + schema["layers"][i]["name"] + '</h5>';
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j]
      myField = new Field(field)
      form = form + myField.getField();
    }
    form = form + "</div>";
  }
  return form;
}

Collection.prototype.handleFieldUI = function(schema){
  Collection.prototype.applyBrowserLocation();
  for(i=0; i<schema["layers"].length;i++){
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j]
      myField = new Field(field)
      myField.completeFieldRequirement();
    }
    form = form + "</div>";
  }
  $("#collectionId").val(schema.id)
}

Collection.prototype.addDataToCollectionList = function(collection_schema){
  for(var i=0; i< collection_schema.length; i++){
    item = Collection.prototype.getListTemplate(collection_schema[i])
    $("#listview").append(item);
  }
  $("#mobile-sites-main").hide();
}

Collection.prototype.getListTemplate = function(collection){
  item = '<li data-corners="false" data-shadow="false" data-iconshadow="true" data-wrapperels="div" data-icon="arrow-r" data-iconpos="right" data-theme="c" class="ui-btn ui-btn-up-c ui-btn-icon-right ui-li-has-arrow ui-li ui-first-child ui-last-child">' + 
            '<div class="ui-btn-inner ui-li">' + 
              '<div class="ui-btn-text">' +
                '<a style="cursor: pointer;" onclick="Collection.prototype.createSite(' + collection["id"] + ')"' + ' href="javascript:void(0)" class="ui-link-inherit">' + collection["name"] + '</a>' + 
              '</div>' + 
              '<span class="ui-icon ui-icon-arrow-r ui-icon-shadow">&nbsp;</span>' +
            '</div>' +
          '</li>';
  return item;
}

Collection.prototype.applyBrowserLocation = function(){
  Collection.prototype.getLocation();
}

Collection.prototype.showError = function(error){
  switch(error.code){
    case error.PERMISSION_DENIED:
      x.innerHTML="User denied the request for Geolocation."
      break;
    case error.POSITION_UNAVAILABLE:
      x.innerHTML="Location information is unavailable."
      break;
    case error.TIMEOUT:
      x.innerHTML="The request to get user location timed out."
      break;
    case error.UNKNOWN_ERROR:
      x.innerHTML="An unknown error occurred."
      break;
  }
}

Collection.prototype.getLocation = function(){
  if (navigator.geolocation){
    navigator.geolocation.getCurrentPosition(Collection.prototype.showPosition, Collection.prototype.showError);
  }
  else{
    x.innerHTML="Geolocation is not supported by this browser.";
  }
}

Collection.prototype.showPosition = function(position){
  $("#lat").val(position.coords.latitude);
  $("#lng").val(position.coords.longitude);
}

Collection.prototype.goHome = function(){
  $("#mobile-collections-main").show();
  $("#mobile-sites-main").hide();
  $("#name").val("");
}

