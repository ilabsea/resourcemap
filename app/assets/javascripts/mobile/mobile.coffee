# mobileinit
$( document ).bind "mobileinit", -> $.extend $.mobile, {

  ## do not initialize jquery mobile on page load
  # autoInitializePage: false

  ## do not send ajax request when navigating page  
  ajaxEnabled: false
  
}
