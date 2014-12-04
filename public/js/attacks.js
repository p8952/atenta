$(document).ready(function(){
	setInterval(function(){
		$(".attacks").children("p").remove();
		var start_time = new Date();
		var end_time = new Date();
		start_time = (start_time.getTime() - 5000) / 1000;
		end_time = (end_time.getTime() / 1000);
		$.getJSON("/api/" + start_time + "/" + end_time, function(data) {
			jQuery.each(data, function() {
				$(".attacks").append("<p>" + this.source_ip + "</p>");
			});
		});
	}, 5000);
});
