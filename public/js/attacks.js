$(document).ready(function(){
	getAttacks();
	setInterval(getAttacks, 30000);
});

function getAttacks(){
	$.getJSON("/attacks", function(data) {
		//$(".attack").remove();
		jQuery.each(data, function() {
			$(".attacks").append(
				"<tr class=\"attack\">" +
				"<td>" + this.timestamp + "</td>" +
				"<td>" + this.source_ip + " (" + this.source_geo + ")" + "</td>" +
				"<td>" + this.target_ip + " (" + this.target_geo + ")" + "</td>" +
				"</tr>");
		});
	});
};
