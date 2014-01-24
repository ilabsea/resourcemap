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
      data = pendingSites[i]["formData"];
      Collection.prototype.ajaxCreateOfflineSite(pendingSites[i]["collectionId"], data);
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
  if(Collection.prototype.validateData(collectionId)){    
    if(window.navigator.onLine){
      var formData = new FormData($('form')[0]);
      Collection.prototype.ajaxCreateSite(collectionId, formData);
    }
    else{
      var offlineData = Collection.prototype.getFormValue();
      Collection.prototype.storeOfflineData(collectionId, offlineData);
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
  Collection.prototype.showErrorMessage("Offline site saved locally.");
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
        var properties = JSON.parse(data.responseText);
        var error = "";
        for(var i=0;i<properties.length; i++){
          error = error + properties[i] + " .";
        }
        Collection.prototype.showErrorMessage("Save new site failed!" + error);
      },
      data: formData,
      contentType: false,
      processData: false,
      cache: false
  });
}

Collection.prototype.ajaxCreateOfflineSite = function(collectionId, formData){
  $.ajax({
      url: '/mobile/collections/' + collectionId + '/create_offline_site',  //Server script to process data
      type: 'POST',
      success: function(){
        Collection.prototype.goHome();
        Collection.prototype.showErrorMessage("Locally saved sites synced successfully.");
      },
      error: function(data){
        Collection.prototype.showErrorMessage("Locally saved sites synced failed.");
      },
      data: formData,
      cache: false
  });
}

Collection.prototype.validateData = function(collectionId){
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

  for(var k=0; k< window.collectionSchema.length; k++){
    if(window.collectionSchema[k]["id"] == collectionId){
      schema = window.collectionSchema[k];
      for(i=0; i<schema["layers"].length;i++){
        for(j=0; j<schema["layers"][i]["fields"].length; j++){
          var field = schema["layers"][i]["fields"][j];
          switch(field["kind"])
          {
            case "email":
              value = $("#" + field["code"]).val();
              if(Collection.prototype.validateEmail(value) == false){
                Collection.prototype.showErrorMessage(field["name"] + "is not a valid email value.");
                return false;
              }              
              break;
            case "numeric":
              value = $("#" + field["code"]).val();
              if(Collection.prototype.validateNumeric(value) == false){
                Collection.prototype.showErrorMessage(field["name"] + "is not valid numeric value.");
                return false;
              }              
              break;
          }
        }
        form = form + "</div>";
      }
    }
  }

  return true;
}

Collection.prototype.validateEmail = function(email) { 
  if(email == ""){
    return true;
  }
  else{
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
  }
}

Collection.prototype.validateNumeric = function(number) { 
  if(number == ""){
    return true;
  }
  else{
    var RE = /^-{0,1}\d*\.{0,1}\d+$/;
    return (RE.test(number));
  }
}

Collection.prototype.showErrorMessage = function(text){
  $.mobile.showPageLoadingMsg( $.mobile.pageLoadErrorMessageTheme, text, true );
  // hide after delay
  setTimeout( $.mobile.hidePageLoadingMsg, 2000 );
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
    if(collection_schema.length > 1 && i == 0){
      classListName = "ui-first-child" 
    }
    else if(collection_schema.length > 1 && i == (collection_schema.length - 1)){
      classListName = "ui-last-child"
    }
    else{
      classListName = ""
    }
    item = Collection.prototype.getListTemplate(collection_schema[i], classListName)
    $("#listview").append(item);
  }
  $("#mobile-sites-main").hide();
}

Collection.prototype.getListTemplate = function(collection, classListName){
  item = '<li data-corners="false" data-shadow="false" data-iconshadow="true" data-wrapperels="div" data-icon="arrow-r" data-iconpos="right" data-theme="c" class="ui-btn ui-btn-up-c ui-btn-icon-right ui-li-has-arrow ui-li ' + classListName + '" >' + 
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

Collection.prototype.getFormValue = function(){
  var site = {};
  var properties = {};
  var elements = $("#formSite")[0].elements;
  var propertyIds = []
  for(var i=0; i< elements.length; i++){
    if(elements[i].name.indexOf("properties") == 0 ){
      index = elements[i].name.replace(/[^0-9]/g, '')
      if($.inArray(index, propertyIds) == -1){
        if(elements[i].type == "file"){
          properties[index] = elements[i].getAttribute("data");
        }
        else if(elements[i].type == "checkbox"){
          if(elements[i].checked){
            if(elements[i].getAttribute("datatype") == "yes_no"){
              properties[index] = elements[i].checked;
            }
            else if(elements[i].getAttribute("datatype") == "select_many"){
              properties[index] = elements[i].value;
            }
          }          
        }
        else{          
          properties[index] = elements[i].value;
        }
        propertyIds.push(index);
      }
      else{
        if(elements[i].checked){
          if(!(Object.prototype.toString.call( properties[index] ) === '[object Array]')){
            properties[index] = [parseInt(properties[index])];
          } 
          properties[index].push(parseInt(elements[i].value));
        }
      }
    }
    else{
      if(elements[i].name != ""){
        site[elements[i].name] = elements[i].value;
      }      
    }
  }
  site["properties"] = properties;
  return site;
}

Collection.prototype.handleFileUpload = function(el){
  var file = el.files[0];
  var reader = new FileReader();
  reader.readAsDataURL(file)
  reader.onload = function (event) {    
    el.setAttribute('data', reader.result);
  };
}
