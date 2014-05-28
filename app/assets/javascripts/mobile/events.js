
$(document).on("mobileinit", function() {
  return $.extend($.mobile, {
    ajaxEnabled: false
  });
});

$(function() {
  return $('#site-page').on("pagebeforeshow", function() {
    return $('#site-page').trigger("pagecreate");
  });
});

$(".numeric").keydown(function(event) {
    // Allow: backspace, delete, tab, escape, enter and .
    if ( $.inArray(event.keyCode,[46,8,9,27,13,190]) !== -1 ||
         // Allow: Ctrl+A
        (event.keyCode == 65 && event.ctrlKey === true) || 
         // Allow: home, end, left, right
        (event.keyCode >= 35 && event.keyCode <= 39)) {
             // let it happen, don't do anything
             return;
    }
    else {
        // Ensure that it is a number and stop the keypress
        if (event.shiftKey || (event.keyCode < 48 || event.keyCode > 57) && (event.keyCode < 96 || event.keyCode > 105 )) {
            event.preventDefault(); 
        }   
    }
});