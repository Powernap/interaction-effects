// 2D Color interpolation: http://bl.ocks.org/syntagmatic/5bbf30e8a658bcd5152b
var Transferfunction2D = function(color1, color2) {
	this.color1 = color1;
	this.color2 = color2;
	this.X = d3.scale.linear()
		.domain([0, 1])
		// .range(['white', 'blue']);
			.range(['white', this.color1]);

	this.Y = d3.scale.linear()
		.domain([0, 1])
		// .range(['white', 'red']);
			.range(['white', this.color2]);
}

Transferfunction2D.prototype.getColor = function(x, y) {
		var color = d3.scale.linear()
			.domain([-1,1])
			.range([this.X(x), this.Y(y)])
			.interpolate(d3.interpolateLab);
		var strength = (y - x);
		var currentColor = color(strength)
		return (currentColor);
}

Transferfunction2D.prototype.testTransferfunction2D = function(x, y, id) {
	document.getElementById(id).style.backgroundColor = this.getColor(x, y);
}