

/**
 * @constructor
 */
window.CommandList = function CommandList(element) {
    if (this === window) {
	return new CommandList(element);
    }
    var svg = $('svg');
    var svgElement = svg[0];
    var foreignObject = $(document.createElementNS(svgElement.namespaceURI, 'foreignObject'))
	    .attr('width', '250px')
	    .attr('height', '250px');

    this.close = function() {
	console.log('close');
	foreignObject.remove();
    };

    var div1 = $('<div>')
	    .attr('class', 'name-me1');
    var div2 = $('<div>')
	    .attr('class', 'name-me2');
    var close = $('<div>')
	    .attr('class', 'close')
	    .on('click', this.close);
    var ul = $('<ul>')
	    .attr('class', 'list')
	    .append($('<li>').append('netstat netstat netstat netstat netstat netstat netstat'))
	    .append($('<li>').append('error log'))
	    .append($('<li>').append('banana peels'))
	    .append($('<li>').append('eggplants'))
	    .append($('<li>').append('netstat netstat netstat netstat netstat netstat netstat'))
	    .append($('<li>').append('error log'))
	    .append($('<li>').append('banana peels'))
	    .append($('<li>').append('eggplants'))
	    .append($('<li>').append('netstat netstat netstat netstat netstat netstat netstat'))
	    .append($('<li>').append('error log'))
	    .append($('<li>').append('banana peels'))
	    .append($('<li>').append('eggplants'))
	    .append($('<li>').append('netstat netstat netstat netstat netstat netstat netstat'))
	    .append($('<li>').append('error log'))
	    .append($('<li>').append('banana peels'))
	    .append($('<li>').append('eggplants'))
	    .append($('<li>').append('netstat netstat netstat netstat netstat netstat netstat'))
	    .append($('<li>').append('error log'))
	    .append($('<li>').append('banana peels'))
	    .append($('<li>').append('eggplants'));
    div1.append(div2);
    div2.append(close).append(ul);
    foreignObject.append(div1);

    /* either a raw SVG element or a jQuery selection may be passed
     * in. */
    element = $(element);

    this.open = function() {
	var p = svgElement.createSVGPoint()
		.matrixTransform(element[0].getTransformToElement(svg[0]));
	foreignObject.attr('x', p.x - 2).attr('y', p.y - 2);
	console.log("hi", svg, p);
	svg.append(foreignObject);
    };

    element.on('click', this.open);

    return this;
};
