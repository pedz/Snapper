
window.NeatBox = function NeatBox(blahblah) {
    if (this === window) {
	return new NeatBox(blahblah);
    }

    this.svg = $('svg');
    this.svgElement = this.svg[0];
    this.foreignObject = $(document.createElementNS(this.svgElement.namespaceURI, 'foreignObject'))
	.attr('class', 'neat-box-foreign-object')
	.attr('width', 1000)
	.attr('height', 1000);

    this.outerDiv = $('<div>')
	.attr('class', 'neat-box-outer-div');

    this.innerDiv = $('<div>')
	.attr('class', 'neat-box-inner-div');

    this.closeButton = $('<div>')
	.attr('class', 'neat-box-close-button');

    this.width = function(pixels) {
	this.outerDiv.css('width', pixels.toString() + 'px');
    };

    this.height = function(pixels) {
	this.outerDiv.css('height', pixels.toString() + 'px');
    };

    this.close = function(event) {
	event.data.foreignObject.remove();
    };

    this.foreignObject.append(this.outerDiv);
    this.outerDiv.append(this.innerDiv);
    this.innerDiv.append(this.closeButton).append(blahblah);
    this.width(250);		// 250px starting width
    this.height(250);		// 250px starting height
    this.closeButton.on('click', null, this, this.close);
    return this;
};

/**
 * @constructor
 */
window.CommandList = function CommandList(element) {
    if (this === window) {
	return new CommandList(element);
    }

    function close() {
	foreignObject.remove();
    };

    var cmdList = this;
    var svg = $('svg');
    var svgElement = svg[0];
    var foreignObject;
    var close_button = $('<div>').attr('class', 'close');

    /* either a raw SVG element or a jQuery selection may be passed
     * in. */
    element = $(element);

    cmdList.open = function(event) {
	cmdList.ul = $('<ul>')
	    .attr('class', 'list');
	cmdList.list.forEach(function(obj) {
	    var li = $('<li>').append(obj.title);
	    cmdList.ul.append(li);
	    li.open = function(event) {
		// remove the current neatBox from the foreignObject
		// and put ours in its place.
		var pre = $('<pre>')
			.attr('class', 'text-output')
			.append(obj.text);
		cmdList.neatBox.close();
	    };
	    li.on('click', li.open);
	});
	    
	cmdList.neatBox = new NeatBox(cmdList.ul);
	cmdList.neatBox.innerDiv.append(cmdList.ul);

	var p = svgElement
	    .createSVGPoint()
	    .matrixTransform(element[0].getTransformToElement(svgElement));
	cmdList.neatBox.foreignObject.attr('x', p.x - 2).attr('y', p.y - 2);
	svg.append(cmdList.neatBox.foreignObject);
    };

    cmdList.list = [];
    cmdList.add = function(title, text) {
	cmdList.list.push({title: title, text: text});
    };

    element.on('click', cmdList.open);
    return cmdList;
};
