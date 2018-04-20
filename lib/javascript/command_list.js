
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
	    trace('commandElement._click');
	    
	    $('body').off('click', this.options.parent._unclick);
	    this.options.parent.foreignObject.detach();
	    if (!this.dialog.closest('html')[0]) {
		trace('commandElement._click append');
		$('body').append(this.dialog);
		this.dialog.dialog({
		    close: function () {
			trace('commandElement.close option');
			$(this).detach();
			// console.log(this);
			// this.detach();
		    },
		    
		    destroy: function () {
			trace('commandElement.destroy option');
		    },

		    _destroy: function () {
			trace('commandElement._destroy option');
		    }
		});
	    }
	    event.stopPropagation();
	},
	
	_create: function () {
	    trace('commandElement._create');
	    this.dialog = $('<div>');
	    
	    this._on(this.element, { 'click': this._click });
	    this.dialog.text('blah blah blah blah');
	},

	close: function () {
	    trace('commandElement.close');
	},
	
	destroy: function () {
	    trace('commandElement.destroy');
	},

	_destroy: function () {
	    trace('commandElement._destroy');
	},

	dialog: undefined
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
		var li = $('<li>');
		li.text(cmd.name);
		li.commandElement({ text: cmd.text, parent: cmd.parent });
		ul.append(li);
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
	    // trace('commandList._create');
	    if (typeof(this.foreignObject) == 'undefined') {
		// trace('create foreign object');
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

	_destroy: function () {
	    // trace('commandList._destroy');
	},

	svg: undefined,
	foreignObject: undefined,

	addCommand: function (name, command) {
	    this.commandList.push({
		name: name,
		text: command,
		parent: this
	    });
	}
    });
 
})(jQuery);
