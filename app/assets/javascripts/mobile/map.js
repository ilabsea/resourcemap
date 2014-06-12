$(function() {
  var canvasId = "#map-canvas" ;
  $canvas =  $(canvasId);
  if($canvas){
    var height = $(window).height() - 50;
    var width  = $(window).width();

    $(canvasId).height(height);
    $(canvasId).width(width);

    Collection.createMap(canvasId);
  }
}); 