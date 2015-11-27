
// window.NeatBox = function NeatBox(blahblah) {
//     if (this === window) {
// 	return new NeatBox(blahblah);
//     }

//     this.svg = $('svg');
//     this.svgElement = this.svg[0];
//     this.foreignObject = $(document.createElementNS(this.svgElement.namespaceURI, 'foreignObject'))
// 	.attr('class', 'neat-box-foreign-object')
// 	.attr('width', 1000)
// 	.attr('height', 1000);

//     this.outerDiv = $('<div>')
// 	.attr('class', 'neat-box-outer-div');

//     this.innerDiv = $('<div>')
// 	.attr('class', 'neat-box-inner-div');

//     this.closeButton = $('<div>')
// 	.attr('class', 'neat-box-close-button');

//     this.width = function(pixels) {
// 	this.outerDiv.css('width', pixels.toString() + 'px');
//     };

//     this.height = function(pixels) {
// 	this.outerDiv.css('height', pixels.toString() + 'px');
//     };

//     this.close = function(event) {
// 	event.data.foreignObject.remove();
//     };

//     this.foreignObject.append(this.outerDiv);
//     this.outerDiv.append(this.innerDiv);
//     this.innerDiv.append(this.closeButton).append(blahblah);
//     this.width(250);		// 250px starting width
//     this.height(250);		// 250px starting height
//     this.closeButton.on('click', null, this, this.close);
//     return this;
// };

// /**
//  * @constructor
//  */
// window.CommandList = function CommandList(element) {
//     if (this === window) {
// 	return new CommandList(element);
//     }

//     function close() {
// 	foreignObject.remove();
//     };

//     var cmdList = this;
//     var svg = $('svg');
//     var svgElement = svg[0];
//     var foreignObject;
//     var close_button = $('<div>').attr('class', 'close');

//     /* either a raw SVG element or a jQuery selection may be passed
//      * in. */
//     element = $(element);

//     cmdList.open = function(event) {
// 	cmdList.ul = $('<ul>')
// 	    .attr('class', 'list');
// 	cmdList.list.forEach(function(obj) {
// 	    var li = $('<li>').append(obj.title);
// 	    cmdList.ul.append(li);
// 	    li.open = function(event) {
// 		// remove the current neatBox from the foreignObject
// 		// and put ours in its place.
// 		var pre = $('<pre>')
// 			.attr('class', 'text-output')
// 			.append(obj.text);
// 		cmdList.neatBox.close();
// 	    };
// 	    li.on('click', li.open);
// 	});
	    
// 	cmdList.neatBox = new NeatBox(cmdList.ul);
// 	cmdList.neatBox.innerDiv.append(cmdList.ul);

// 	var p = svgElement
// 	    .createSVGPoint()
// 	    .matrixTransform(element[0].getTransformToElement(svgElement));
// 	cmdList.neatBox.foreignObject.attr('x', p.x - 2).attr('y', p.y - 2);
// 	svg.append(cmdList.neatBox.foreignObject);
//     };

//     cmdList.list = [];
//     cmdList.add = function(title, text) {
// 	cmdList.list.push({title: title, text: text});
//     };

//     element.on('click', cmdList.open);
//     return cmdList;
// };

(function($, undefined) {
    var trace = function (args) {
	if (false) {
	    console.log.apply(console, arguments);
	}
    };

    $.widget("pedz.commandElement", {
	options: {
	    text: "",
	    parent: undefined
	},

	_unclick: function(event) {
	    trace('commandElement._unclick');
	},

	_click: function(event) {
	    var div = $('div');

	    trace('commandElement._click', this.options);
	    div.append(this.options.text);
	    this.options.parent.foreignObject.empty();
	    this.options.parent.foreignObject.append($('<div>foo</div>').dialog());
	    event.stopPropagation();
	},

	_create: function () {
	    this._on(this.element, { "click": this._click });
	}
    });

    $.widget("pedz.commandList", {
	options: {
	},

	// Called via click event when list is open
	_unclick: function (event) {
	    var d = event.data;
	    trace('commandList._unlick', event, d);

	    $('body').off('click', this._unclick);
	    d.foreignObject.empty();
	    d.foreignObject.remove();
	},

	_click: function(event) {
	    var ul = $("<ul>");
	    var svgElement = this.svg[0];
	    var p = svgElement
		    .createSVGPoint()
		    .matrixTransform(this.element[0].getTransformToElement(svgElement));

	    trace("commandList._click");
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
	    if (typeof(this.foreignObject) == "undefined") {
		trace('create foreign object');
		var svg = $("svg");

		this.foreignObject = $(document.createElementNS(svg[0].namespaceURI, 'foreignObject'))
		    .attr('class', 'command-list-foreign-object')
		    .attr('width', 100)
		    .attr('height', 100);
		this.svg = svg;
	    }
	    this.commandList = [];
	    this._on(this.element, { "click": this._click });
	},

	svg: undefined,
	foreignObject: undefined,

	addCommand: function (name, command) {
	    var li = $("<li>" + name + "</li>");

	    trace('addCommand', this);
	    li.commandElement({ text: command, parent: this });
	    this.commandList.push(li);
	}
    });
 
})(jQuery);
