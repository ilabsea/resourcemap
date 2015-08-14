(function(){
	$(".key-map-integer").controlKeyInput({
	  allowChar: /[0-9\-]/,
	  allow: function(input, char){
	    if(char == "-" && ($.caretPosition(input) !=0 || input.value.indexOf(char) != -1 ) )
	      return false ;
	    return true ;	
	  },
	  failed: function(input, char){
	  	console.log("char: " + char + " is not acceptable")
	  },
	  success: function(input, char){
	  	console.log("char: " + char + " is accepted")
	  }
	});

	$(".key-map-decimal").controlKeyInput({
	  allowChar: /[0-9\-\.]/,
	  allow: function(input, char){
	    if(char == "-" && ($.caretPosition(input) !=0 || input.value.indexOf(char) != -1 ) )
	      return false ;
	 	if(char == '.'){
	 		if($.caretPosition(input) == 1 && input.value.indexOf('-') == 0)
	 			return false;
	 		if($.caretPosition(input) ==0 || input.value.indexOf(char) != -1 )
	 	  		return false ;

	 	}

	    return true ;	
	  },
	  failed: function(input, char){
	  	console.log("char: " + char + " is not acceptable")
	  },
	  success: function(input, char){
	  	console.log("char: " + char + " is accepted")
	  }
	});
})(jQuery);
