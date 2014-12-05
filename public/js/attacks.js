$(document).ready(function(){
	setInterval(getAttacks, 10000);
});

function getAttacks(){
	$.getJSON("/attacks", function(data) {
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
};
