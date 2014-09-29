
function Field (field) {
  this.id = field != null ? field["id"] : void(0);
  this.name = field != null ? field["name"] : void(0);
  this.kind = field != null ? field["kind"] : void(0);
  this.code = field != null ? field["code"] : void(0);
  this.value = (field != null && ("value" in field)) ? field["value"] : "";
  this.label = this.name;
  if(field["is_mandatory"] == true){
    this.label = "* " + this.name
  }
  if(this.kind == 'hierarchy'){
    this.sub = setHierarchyData(field);
  }else if(this.kind == 'select_one' || this.kind == 'select_many'){
    this.options = [];
    for(var i=0; i<field["config"]["options"].length; i++){
      this.options.push(new Option(field["config"]["options"][i]));
    }
  }else if(this.kind == 'numeric'){
    this.range = field["config"]["range"];
  }

  if(field["is_enable_field_logic"] == true){
    this.field_logics = [];
    for(var i=0; i<field["config"]["field_logics"].length; i++){
      this.field_logics.push(new FieldLogic(field["config"]["field_logics"][i]));
    }
  }
};
 
Field.prototype.getField = function() {
  switch(this.kind)
  {
    case "text":
      return this.getTextField();
      break;
    case "numeric":
      return this.getNumericField();
      break;
    case "date":
      return this.getDateField();
      break;
    case "yes_no":
      return this.getYesNoField();
      break;
    case "select_one":
      return this.getSelectOneField();
      break;
    case "select_many":
      return this.getSelectManyField();
      break;
    case "phone number":
      return this.getPhoneNumberField();
      break;
    case "email":
      return this.getEmailField();
      break;
    case "photo":
      return this.getPhotoField();
      break;
    case "hierarchy":
      return this.getHierarchyField();
      break;
    default:
      return this.getTextField();
  }
};

Field.prototype.completeFieldRequirement = function() {
  switch(this.kind)
  {
    case "yes_no":
      // $("#" + this.code).checkboxradio("refresh");
      break;
    case "hierarchy":
      $("#" + this.code).selectmenu();
      break;      
    case "select_one":
      $("#" + this.code).selectmenu();
      break;
    case "select_many":
      // $("input[type='checkbox']").prop("checked",true).checkboxradio("refresh");
      break;
  }
}
Field.prototype.getHierarchyField = function() { 

  list = "";
  for(var i=0; i< this.sub.length; i++){
    if(this.sub[i].id == this.value){
      list = list + "<option value='" + this.sub[i].id + "' selected='selected'>" + this.sub[i].label + "</option>" ;
    }else
      list = list + "<option value='" + this.sub[i].id + "' >" + this.sub[i].label + "</option>" ;
  }
  return  '<div class="ui-select" style="margin-left:10px;">' +
              '<label>' + this.label + '</label>'+
              '<select name="properties[' + this.id + ']" id="' + this.code + '"  datatype="hierarchy">' +
                list +
              '</select>' +
          '</div>';

};




Field.prototype.getTextField = function() {  
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.label + '</label>'+
        '<div id="div_wrapper_' + this.code + '" class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input value="' + this.value +'" name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="text" datatype="text">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getNumericField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.label + '</label>'+
        '<div id="div_wrapper_' + this.code + '" class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input value="' + this.value +'" name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="number" datatype="numberic">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getDateField = function() {
  return  '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
            '<div class="ui-controlgroup-controls">'+
              '<label>' + this.label + '</label>'+
              '<div id="div_wrapper_' + this.code + '" class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
                '<input value="' + this.value.split("T")[0] +'" name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="date"  datatype="date">'+
              '</div>'+
              '<div class="clear"></div>'+
            '</div>'+
          '</div>';
};

Field.prototype.getYesNoField = function() {
  if(this.value){
    checked = "checked";
  }
  else{
    checked = "";
  }
  return '<div class="ui-controlgroup-controls">' +
      '<div class="ui-checkbox " style="margin-left:10px;margin-top:10px">' + 
          '<label for="' + this.code + '" data-theme="c" class="ui-btn ui-btn-icon-left ui-corner-all ui-btn-up-c">' +
            '<span class="ui-btn-inner">'+
              '<span style="font-weight:normal;">' + this.label + '</span>' +
              '<input ' + checked + ' type="checkbox" name="properties[' + this.id + ']" id="' + this.code + '" class="custom"  datatype="yes_no" onchange="Collection.prototype.setFieldFocus('+this.id+','+this.code+',\''+this.kind+'\')">' +
            '</span>'+
          '</label>'+
      '</div>'+
    '</div>';
};

Field.prototype.getSelectOneField = function() {
  list = "";
  for(var i=0; i< this.options.length; i++){
    if(this.options[i]["id"] == this.value){
      list = list + "<option value='" + this.options[i]["id"] + "' selected='selected' >" + this.options[i]["name"] + "</option>" ;
    }
    else{
      list = list + "<option value='" + this.options[i]["id"] + "' >" + this.options[i]["name"] + "</option>" ;
    }
  }

  return  '<div class="ui-select" style="margin-left:10px;">' +
              '<label>' + this.label + '</label>'+
              '<select name="properties[' + this.id + ']" id="' + this.code + '"  datatype="select_one" onchange="Collection.prototype.setFieldFocus('+this.id+',this.value,\''+this.kind+'\')">' +
                list +
              '</select>' +
          '</div>';
};

Field.prototype.getSelectManyField = function() {
  list = "";
  for(var i=0; i< this.options.length; i++){ 
    if(this.value.indexOf(this.options[i]["id"]) >= 0){
      checked = "checked";
    }
    else{
      checked = "";
    }
    if(this.options.length > 1 && i == 0){
      classListName = "ui-first-child" 
    }else if(this.options.length > 1 && i == (this.options.length - 1)){
      classListName = "ui-last-child"
    }else{
      classListName = ""
    }
    list = list + '<li data-corners="false" data-shadow="false" data-iconshadow="true" data-wrapperels="div" data-icon="arrow-r" data-iconpos="right" data-theme="c" class="ui-btn ui-btn-up-c ui-btn-icon-right ui-li-has-arrow ui-li ' + classListName + '" >' + 
        '<div class="ui-btn-inner ui-li">' + 
          '<div class="ui-checkbox" style="padding-top: 10px; height: 25px;" >' +
              '<label for="' + this.id + "-" + this.options[i]["code"] + '"  data-theme="c" style="margin:0px;">' +  
                '<span style="padding: 10px 100% 5px 40px;;font-weight:normal;height:20px;color: #2f3e46;text-decoration: none !important;" class="ui-link-inherit">' + this.options[i]["name"] + '</span>' +
                '<input class="field_' + this.id + '" onchange="Collection.setFocusOnField(' + this.id + ')" ' + checked + ' type="checkbox" value="' + this.options[i]["id"] + '" name="properties[' + this.id + '][]" id="' + this.id + "-" + this.options[i]["code"] + '" datatype="select_many">' +
              '</label>'+
          '</div>' +
        '</div>' +
      '</li>';
  }

  return  '<div class="ui-controlgroup-controls" style="margin-left:10px;">' + 
            '<div class="ui-controlgroup-controls"  style="margin-bottom:10px;">' + 
              '<label>' + this.label + '</label>'+ 
            '</div>'+
            '<div class="ui-controlgroup-controls">' + 
              '<ul id="listSitesView" class="ui-listview ui-listview-inset ui-corner-all ui-shadow" data-role="listSitesView" data-inset="true">' +
                list + 
              '</ul>' +
            '</div>'+
          '</div>' ;
};

Field.prototype.getPhoneNumberField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.label + '</label>'+
        '<div id="div_wrapper_' + this.code + '" class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input value="' + this.value +'" name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="tel"  datatype="phone number">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getEmailField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.label + '</label>'+
        '<div id="div_wrapper_' + this.code + '" class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input value="' + this.value +'" name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="email"  datatype="email">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getPhotoField = function() {
  displayDiv = ""
  if(this.value != ""){
    displayDiv = "<img style='width:100%;' src='/photo_field/" + this.value + "' alt='" + this.value + "' />";
  }
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.label + '</label> <br /><br />'+ displayDiv +
        '<input type="hidden" name="properties[' + this.id + ']" value="' + this.value + '" />' +
        '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input onchange="Collection.prototype.handleFileUpload(this)" class="ui-input-text ui-body-c" type="file" data-clear-btn="true" name="properties[' + this.id + ']" id="' + this.code + '"  datatype="photo">'+          
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

function setSubHierarchy(sub, field, level){
  if("sub" in field){
    for(var i=0; i<field.sub.length; i++){
      space ="";
      for(var j=0; j<level; j++){
        space = space + "&nbsp;";
      }
      // console.log(space+field.sub[i].name);
      sub.push(new SubHierarchy(field.sub[i].id, space+field.sub[i].name));
      nSpace = level + 3;
      setSubHierarchy(sub, field.sub[i], nSpace);
    }
  }else{
    return;
  }
}

function setHierarchyData(field){
  var sub = [];
  for(var i=0; i<field.config.hierarchy.length; i++){     
    sub.push(new SubHierarchy(field.config.hierarchy[i].id, field.config.hierarchy[i].name));
    setSubHierarchy(sub, field.config.hierarchy[i], 3);       
  }  
  return sub;
}