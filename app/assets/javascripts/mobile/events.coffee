# mobileinit
$( document ).on "mobileinit", -> $.extend $.mobile, {

  ## do not initialize jquery mobile on page load
  # autoInitializePage: false

  ## do not send ajax request when navigating page  
  ajaxEnabled: false
  
}

# page events
$ ->

  # '#site-page' pagebeforeshow
  $( '#site-page' ).on "pagebeforeshow", -> $( '#site-page' ).trigger "pagecreate" 
