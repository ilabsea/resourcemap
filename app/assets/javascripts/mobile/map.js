$(function() {
  Map.loadMap();
}); 

var Map = {
  loadMap: function(){
    if(window.navigator.onLine){
      var canvasId = "#map-canvas" ;
      $canvas =  $(canvasId);
      if($canvas){
        var height = $(window).height() - 50;
        var width  = $(window).width();

        $canvas.height(height);
        $canvas.width(width);
        Collection.createMap(canvasId);
      }
    }
  }
}