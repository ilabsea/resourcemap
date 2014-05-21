$(function() {
  if( $.mobile !== undefined ) {
   $.extend( $.mobile, {
      savingMessage: {
        theme: "b",
        textVisible: true,
        text: $("#saving-message").text()
      },

      saving: function( action ) {
        if( !action ) {
          return false;
        }

        $.mobile.activePage[ action == 'show' ? 'addClass' : 'removeClass' ]( "ui-disabled" );
        $.mobile.loading( action, $.mobile.savingMessage );
      }
    }); 
  }

});