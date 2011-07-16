function expand(){
	var link = $(this);
	link.toggleClass('inited');
	if(link.is('.inited')){
		link.html('Скрыть все ответы');
		$('.questions li').removeClass('hide');
	}else{
		link.html('Показать все ответы');
		$('.questions li').addClass('hide');
	}
};

function init_unhide_pairs(){
	$('.questions li span.pseudo-link').each(function(i){
        var obj = $(this);
        obj.click(function(){
 			obj.parent('li').toggleClass('hide');
        });
    });
} 



$(function(){
	init_unhide_pairs();
	$('.data .pseudo-link').click(expand)
})


function getParameterByName( name )
{
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return "";
  else
    return results[1];
};
$(document).ready(function() {

	  selectedquestion = getParameterByName('id'); 
	  
	  if(selectedquestion != ''){
       		$("#"+selectedquestion).parent('li').removeClass('hide');
$.scrollTo("#"+selectedquestion);
    }

});
