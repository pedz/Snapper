
(function($, undefined) {
    var trace = function (args) {
	if (true) {
	    console.log.apply(console, arguments);
	}
    };

    $.widget('pedz.commandElement', {
	options: {
	    text: '',
	    parent: undefined
	},

	_unclick: function(event) {
	    trace('commandElement._unclick');
	},

	_click: function(event) {
	    var div = $('<div>');

	    trace('commandElement._click');
	    div.text('blah blah blah blah');
	    this.options.parent.foreignObject.empty();
	    $('body').append(div);
	    div.dialog();
	    // this.options.parent.foreignObject.append(div);
	    event.stopPropagation();
	},

	_create: function () {
	    this._on(this.element, { 'click': this._click });
	}
    });

    $.widget('pedz.commandList', {
	options: {
	},

	// Called via click event when list is open
	_unclick: function (event) {
	    var d = event.data;
	    trace('commandList._unlick');

	    $('body').off('click', this._unclick);
	    d.foreignObject.empty();
	    d.foreignObject.remove();
	},

	_click: function(event) {
	    var ul = $('<ul>');
	    var svgElement = this.svg[0];
	    var p = svgElement
		    .createSVGPoint()
		    .matrixTransform(this.element[0].getTransformToElement(svgElement));

	    trace('commandList._click');
	    this.commandList.forEach(function (cmd) {
		ul.append(cmd);
	    });
	    this.foreignObject
		.attr('x', p.x - 2)
		.attr('y', p.y - 2);
	    this.foreignObject.append(ul);
	    ul.menu();
	    this.svg.append(this.foreignObject);
	    $('body').on('click', this, this._unclick);
	    event.stopPropagation();
	},

	_create: function () {
	    if (typeof(this.foreignObject) == 'undefined') {
		trace('create foreign object');
		var svg = $('svg');

		this.foreignObject = $(document.createElementNS(svg[0].namespaceURI, 'foreignObject'))
		    .attr('class', 'command-list-foreign-object')
		    .attr('width', 100)
		    .attr('height', 100);
		this.svg = svg;
	    }
	    this.commandList = [];
	    this._on(this.element, { 'click': this._click });
	},

	svg: undefined,
	foreignObject: undefined,

	addCommand: function (name, command) {
	    var li = $('<li>');

	    li.text(name);
	    trace('addCommand');
	    li.commandElement({ text: command, parent: this });
	    this.commandList.push(li);
	}
    });
 
})(jQuery);
