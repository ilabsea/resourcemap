
function prepareFlushMessage(id){
	var content = $(id).html();	
  if(content.trim() != ""){
		parent = $(id).children()[0];
		if(parent){
			text = parent.children[0].innerHTML;
			showFlushMessage(text);
		}
	}
}

function showFlushMessage(message){
	jq.mobile.showPageLoadingMsg( jq.mobile.pageLoadErrorMessageTheme, message, true );
  	setTimeout( jq.mobile.hidePageLoadingMsg, 3000 );
}