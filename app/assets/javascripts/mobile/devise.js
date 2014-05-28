function prepareFlushMessage(id){
	var content = $(id).html();
	console.log(content);
	if(content.trim() != ""){
		console.log("Have content");
		parent = $(id).children()[0];
		console.log(parent);
		if(parent){
			text = parent.children[0].innerHTML;
			showFlushMessage(text);
		}
	}
}

function showFlushMessage(message){
	$.mobile.showPageLoadingMsg( $.mobile.pageLoadErrorMessageTheme, message, true );
  	setTimeout( $.mobile.hidePageLoadingMsg, 3000 );
}