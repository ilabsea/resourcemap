// Update the appcache for offline

$(document).ready(function() {
 if (window.applicationCache) {
   applicationCache.addEventListener('updateready', function() {        
     if (window.applicationCache.status == window.applicationCache.UPDATEREADY) {
       window.applicationCache.swapCache();
       console.log("appcache updated");
       // window.location.reload();
     }
   });
 }
});
