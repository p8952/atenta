$(document).ready(function(){
	jQuery.ajaxSetup({async:false});
	setInterval(function(){
		var time = 0;
		$.get("/time", function(data) {
			time = data;
		});

		var text_time = new Date(0);
		text_time.setUTCSeconds(time);
		$(".bottom-right").text(text_time);

		var start_time = (time - 30);
		var end_time = time
		$.getJSON("/api/" + start_time + "/" + end_time, function(data) {
			$(".attack").remove();
			jQuery.each(data, function() {
				$(".attacks").append(
					"<tr class=\"attack\">" +
					"<td>" + this.timestamp + "</td>" +
					"<td>" + this.source_ip + "</td>" +
					"<td>" + this.target_ip + "</td>" +
					"</tr>");
			});
		});
	}, 30000);
});
