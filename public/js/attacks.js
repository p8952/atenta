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
				"<td>" + this.source_ip + " (<img src=\"\/flag\/" + this.source_geo + ".png\">)" + "</td>" +
				"<td>" + this.target_ip + " (<img src=\"\/flag\/" + this.target_geo + ".png\">)" + "</td>" +
				"</tr>");
		});
	});
};
