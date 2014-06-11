
function Field (field) {
  this.id = field != null ? field["id"] : void(0);
  this.name = field != null ? field["name"] : void(0);
  this.kind = field != null ? field["kind"] : void(0);
  this.code = field != null ? field["code"] : void(0);
  if(this.kind == 'select_one' || this.kind == 'select_many'){
    this.options = [];
    for(var i=0; i<field["config"]["options"].length; i++){
      this.options.push(new Option(field["config"]["options"][i]));
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
    case "select_one":
      $("#" + this.code).selectmenu();
      break;
    case "select_many":
      // $("input[type='checkbox']").prop("checked",true).checkboxradio("refresh");
      break;
  }
}

Field.prototype.getTextField = function() {  
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.name + '</label>'+
        '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="text" datatype="text">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getNumericField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.name + '</label>'+
        '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="number" datatype="numberic">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getDateField = function() {
  return  '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
            '<div class="ui-controlgroup-controls">'+
              '<label>' + this.name + '</label>'+
              '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
                '<input name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="date"  datatype="date">'+
              '</div>'+
              '<div class="clear"></div>'+
            '</div>'+
          '</div>';
};

Field.prototype.getYesNoField = function() {
  return '<div class="ui-controlgroup-controls">' +
      '<div class="ui-checkbox " style="margin-left:10px;margin-top:10px">' + 
          '<label for="' + this.code + '" data-theme="c" class="ui-btn ui-btn-icon-left ui-corner-all ui-btn-up-c">' +
            '<span class="ui-btn-inner">'+
              '<span style="font-weight:normal;">' + this.name + '</span>' +
              '<input type="checkbox" name="properties[' + this.id + ']" id="' + this.code + '" class="custom"  datatype="yes_no">' +
            '</span>'+
          '</label>'+
      '</div>'+
    '</div>';
};

Field.prototype.getSelectOneField = function() {
  list = "";
  for(var i=0; i< this.options.length; i++){
    list = list + "<option value='" + this.options[i]["id"] + "' >" + this.options[i]["name"] + "</option>" ;
  }

  return  '<div class="ui-select" style="margin-left:10px;">' +
              '<label>' + this.name + '</label>'+
              '<select name="properties[' + this.id + ']" id="' + this.code + '"  datatype="select_one">' +
                list +
              '</select>' +
          '</div>';
};

Field.prototype.getSelectManyField = function() {
  list = "";
  for(var i=0; i< this.options.length; i++){ 
    list = list +   
      '<div class="ui-checkbox">' +         
          '<label for="' + this.options[i]["code"] + '"  for="checkbox-1a" data-theme="c" class="ui-btn ui-btn-icon-left ui-corner-all ui-btn-up-c"  style="margin:0px;">' +  
            '<span class="ui-btn-inner ui-corner-top">'+
              '<span style="font-weight:normal;">' + this.options[i]["name"] + '</span>' +
              '<input type="checkbox" value="' + this.options[i]["id"] + '" name="properties[' + this.id + '][]" id="' + this.options[i]["code"] + '" class="custom"  datatype="select_many">' +
            '</span>'+
          '</label>'+
      '</div>';
  }

  return  '<div class="ui-controlgroup-controls" style="margin-left:10px;">' + 
            '<div class="ui-controlgroup-controls"  style="margin-bottom:10px;">' + 
              '<label>' + this.name + '</label>'+ 
            '</div>'+
            '<div class="ui-controlgroup-controls">' + 
              list + 
            '</div>'+
          '</div>';
};

Field.prototype.getPhoneNumberField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.name + '</label>'+
        '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="tel"  datatype="phone number">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getEmailField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.name + '</label>'+
        '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input name="properties[' + this.id + ']" id="' + this.code + '" class="right w20 ui-input-text ui-body-c" type="email"  datatype="email">'+
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

Field.prototype.getPhotoField = function() {
  return '<div class="ui-corner-all ui-controlgroup ui-controlgroup-vertical" style="margin-left:10px">'+
      '<div class="ui-controlgroup-controls">'+
        '<label>' + this.name + '</label>'+
        '<div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">'+
          '<input onchange="Collection.prototype.handleFileUpload(this)" class="ui-input-text ui-body-c" type="file" data-clear-btn="true" value="" name="properties[' + this.id + ']" id="' + this.code + '"  datatype="photo">'+          
        '</div>'+
        '<div class="clear"></div>'+
      '</div>'+
    '</div>';
};

