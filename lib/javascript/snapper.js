/* Global defines and typedefs used by jsdoc */
/**
 * @see http://api.jquery.com/Types/#jQuery
 * @desc A jQuery object as returned from jQuery()
 * @typedef jQuery
 */
/**
 * @see http://www.w3.org/TR/SVG/struct.html#SVGElement
 * @desc An SVG element as specified by SVG.
 * @typedef SVGElement
 */
/**
 * @see http://www.w3.org/TR/SVG/shapes.html#LineElement
 * @desc A Line element as specified by SVG.
 * @typedef LineElement
 */
/**
 * @see http://www.w3.org/TR/SVG/shapes.html#RectElement
 * @desc A rect element as specified by SVG.
 * @typedef RectElement
 */
/**
 * @see http://www.w3.org/TR/SVG/shapes.html#PolylineElement
 * @desc A Polyline element as specified by SVG.
 * @typedef PolylineElement
 */
/**
 * @see http://www.w3.org/TR/SVG/coords.html#IfnetSVGPoint
 * @desc The Point interface as specified by SVG
 * @typedef SVGPoint
 */
/**
 * @see <a href='../ruby/Device.html'>Device</a>
 * @desc A device entry created by the Ruby code.
 * @typedef {Object} RubyDevice
 */
/**
 * @see <a href='../ruby/Batch.html'>Batch</a>
 * @desc A single run of snapper.rb produces a batch which is output
 * as a JSON object and passed to the {@link Snapper~World#addBatch}
 * routine by the Javascript code produced by the <a
 * href='../ruby/Page.html#method-i-add_data'>Page#add_data</a>
 * method.
 * @typedef {Object} Batch
 */
/**
 * @see <a href='../ruby/Snap.html'>Snap</a>
 * @desc A {@link Batch} has a list of snaps that contain the {@link
 * Db} which contains various entities created at parse time by
 * snapper.rb.  Among the entities are {@link RubyDevice} instances.
 * @typedef {Object} Snap
 */
/**
 * @see <a href='../ruby/Db.html'>Db</a>
 * @desc The main component within a {@link Snap}.
 * @typedef {Object} Db
 */
/**
 * @desc The String value of the id_to_system attribute of the sys0
 * device pulled out of the CuAt table of the ODM database.  e.g. the
 * output of: `lsattr -Elsys0 -a id_to_system -F value`
 * @typedef {String} SystemId
 */
/**
 * @desc The String value of the id_to_partition attribute of the sys0
 * device pulled out of the CuAt table of the ODM database.  e.g. the
 * output of: `lsattr -Elsys0 -a id_to_partition -F value`
 * @typedef {String} PartitionId
 */
/**
 * @desc The SVG or DOM tree of nodes that represent the element.
 * @typedef {jQuery} SVGTree
 */


(
    /**
     * Creates a surrounding syntax environment for the rest of the
     * javascript code.  The loading of the document creates a Snapper
     * instance that is hooked into the global context of window.
     * When it is created, a single World object is created.  Thus
     * window.snapper is a Snapper object and window.snapper.world is
     * a World object.
     *
     * @alias Snapper
     * @constructor
     * @param {DOMWindow} window - The global window
     * @param {DOMDocument} document - The global document
     * @param {undefined} undefined - Javascript undefined
     *
     * @classdesc Snapper is a singleton that creates a static
     * syntactic scope so that the various constructions and helper
     * methods can be called without knowing the full path to them.
     */
    function Snapper(window, document, undefined) {
	"use strict";

	/**
	 * Currently unused global to the Environment that specifies
	 * the SVG namespace
	 * @constant {String}
	 * @default
	 */
	var svgNamespaceURI = "http://www.w3.org/2000/svg";

	/**
	 * @member {jQuery}
	 * @desc A global to the Environment that is the jQuery selection of the SVG tag
	 */
	var svgSelection;

	/**
	 * @member {SVGElement}
	 * @desc The actual SVG tag in the document
	 */
	var svgElement;		// some svg element in the page

	/**
	 * Helper function to create an SVG element
	 * @param {String} tagName - the tag of the element to create such as 'line'
	 * @return {jQuery} a jQuery selection of the newly created DOM element
	 */
	function createElement(tagName) {
	    var newElement;

	    if (typeof svgElement === 'undefined') {
		svgSelection = $('svg');
		svgElement = svgSelection[0];
	    }
	    
	    /*
	     * We append newly created elements to the svg element.
	     * This prevents a bug in Firefox where getBBox does not
	     * work for elements that are not in the DOM tree or
	     * hidden.  The element will later be placed somewhere
	     * else within the tree but that is ok since an element
	     * can have only one parent.
	     */
	    newElement = $(document.createElementNS(svgElement.namespaceURI, tagName));
	    svgSelection.append(newElement);
	    return newElement;
	}

	/**
	 * Create a group element with a rectangle and a name.
	 * @param {String} name - The name of the rectangle or the
	 * text to put into the rectangle
	 * @param {Object} attrs - attributes for the group element,
	 * the rect element and the text element.
	 * @return {jQuery} a jQuery selection with the newly created
	 * 'g' SVG element with an 'rect' SVG element and a 'text' SVG
	 * element inside of it.
	 */
	function createNamedRect(name, attrs) {
	    var g_attrs = {};	// attributes for the group element
	    var r_attrs = {};	// attributes for the rect element
	    var t_attrs = {};	// attributes for the text element

	    if (attrs) {
		if (attrs.class)
		    g_attrs.class = r_attrs.class = t_attrs.class = attrs.class;
		if (attrs.id)
		    g_attrs.id = attrs.id;
		if (attrs.width) {
		    r_attrs.width = attrs.width;
		    t_attrs.x = attrs.width / 2;
		}
		if (attrs.height) {
		    r_attrs.height = attrs.height;
		    t_attrs.y = attrs.height / 2;
		}
	    }
	    return createElement('g').attr(g_attrs)
		.append(createElement('rect').attr(r_attrs))
		.append(createElement('text').attr(t_attrs).append(name));
	}

	/**
	 * Helper function to create an SVG line element
	 * @param {SVGPoint} p1 - Starting point
	 * @param {SVGPoint} p2 - Ending point
	 * @return {LineElement}
	 */
	function line(p1, p2) {
	    var l = createElement('line');
	    var e = l[0];
	    e.setAttributeNS(null, 'x1', p1.x);
	    e.setAttributeNS(null, 'y1', p1.y);
	    e.setAttributeNS(null, 'x2', p2.x);
	    e.setAttributeNS(null, 'y2', p2.y);
	    return l;
	}

	/**
	 * Helper function to create an SVG polyline element
	 * @param {Array.<SVGPoint>} arguments - A list of SVGPoints the
	 * polyline should pass through.
	 * @return {PolylineElement}
	 */
	function polyline() {
	    var len = arguments.length;
	    var points = [];
	    var p = createElement('polyline');
	    var i;

	    for (i = 0; i < len; i += 1)
		points.push(arguments[i].x + "," + arguments[i].y);
	    p[0].setAttributeNS(null, 'points', points.join(' '));
	    return p;
	}

	/**
	 * Helper function to create a string to pass as the value of
	 * the transform attribute.
	 * @param {Number} x - the x value of the transform
	 * @param {Number} y - the y value of the transform
	 * @return {String} The two numbers both surrounded by single
	 * quotes with a comma and a space between. e.g.  "'12.5', '14.8'"
	 */
	function translate(x, y) {
	    return 'translate(' + x + ', ' + y + ')';
	}

	/**
	 * Passed either an array of items to render or a hash whose
	 * values need to be rendered
	 * @param {(Array|Object)} bag - If passed an Array, calls
	 * each elements draw method.  If passed an Object, calls the
	 * draw method of each of the values.
	 * @return {Array.<SVGTree>} Since each draw function returns an
	 * SVG tree, this returns an array of those results.
	 */
	function render(bag) {
	    if (bag instanceof Array) {
		return bag.map(function call_array_element_draw(obj) {
		    return obj.draw();
		});
	    } else {
		return Object.getOwnPropertyNames(bag).map(function call_obj_element_draw(id) {
		    return bag[id].draw();
		});
	    }
	}

	/**
	 * Given an object, returns the rect that represents the object.
	 * @param {Object} obj - obj can be a jQuery object or any of
	 * the objects created here such as a VirtualSwitch or Ent
	 * that has an svg property which is a jQuery object.
	 * @return {RectElement}
	 */
	function get_rect(obj) {
	    if (((obj instanceof jQuery) == false) && ((obj.svg instanceof jQuery) == true))
		obj = obj.svg;

	    if (obj.prop('tagName') == "g")
		return obj.children('rect')[0];
	    return obj[0];
	}

	/**
	 * Currently this is used to draw the polylines from the VEAs
	 * to the virtual switches but I tried to write it generically
	 * so that it can be adopted and used in other places.
	 */
	function connectListToTarget(container, target, list, target_index, target_count) {
	    /*
	     * for below_target, start at bottom left corner
	     */
	    function draw_below_left (obj, index, group) {
		var mid;
		var line;
		var to_padding = obj.padding;

		target_x += delta_x;

		to_point.x = obj.rect.width.baseVal.value / 2;
		to_point.y = 0;
		to_point = to_point.matrixTransform(obj.transform);
		target_point.x = target_x;
		target_point.y = target_y;
		target_point = target_point.matrixTransform(target_transform);

		mid = ((to_point.y - to_padding.top) -
		       (target_point.y + target_padding.bottom)) / target_count;
		mid = (mid * target_index) + (mid * (index + 1) / max_len);

		p2.x = to_point.x;
		p2.y = target_point.y + target_padding.bottom + mid;
		p3.x = target_point.x;
		p3.y = p2.y;
		line = polyline(to_point, p2, p3, target_point);
		obj.object.path_to = line;
		container.svg.append(line);
	    }

	    function draw_below_right (obj, index, group) {
		var mid;
		var line;
		var to_padding = obj.padding;

		target_x += delta_x;

		to_point.x = obj.rect.width.baseVal.value / 2;
		to_point.y = 0;
		to_point = to_point.matrixTransform(obj.transform);
		target_point.x = target_x;
		target_point.y = target_y;
		target_point = target_point.matrixTransform(target_transform);

		mid = ((to_point.y - to_padding.top) -
		       (target_point.y + target_padding.bottom)) / target_count;
		mid = (mid * target_index) + (mid * (group.length - index) / max_len);

		p2.x = to_point.x;
		p2.y = target_point.y + target_padding.bottom + mid;
		p3.x = target_point.x;
		p3.y = p2.y;
		line = polyline(to_point, p2, p3, target_point);
		obj.object.path_to = line;
		container.svg.append(line);
	    }

	    function draw_above_left(obj, index, group) {
		var mid;
		var line;
		var to_padding = obj.padding;

		target_x += delta_x;

		to_point.x = obj.rect.width.baseVal.value / 2;
		to_point.y = obj.rect.height.baseVal.value;   
		to_point = to_point.matrixTransform(obj.transform);
		target_point.x = target_x;
		target_point.y = target_y;
		target_point = target_point.matrixTransform(target_transform);

		mid = ((target_point.y - target_padding.top) -
		       (to_point.y + to_padding.bottom)) / target_count;
		mid = (mid * target_index) + (mid * (group.length - index) / max_len);

		p2.x = to_point.x;
		p2.y = to_point.y + to_padding.bottom + mid;
		p3.x = target_point.x;
		p3.y = p2.y;
		line = polyline(to_point, p2, p3, target_point);
		obj.object.path_to = line;
		container.svg.append(line);
	    }

	    function draw_above_right(obj, index, group) {
		var mid;
		var line;
		var to_padding = obj.padding;

		target_x += delta_x;

		to_point.x = obj.rect.width.baseVal.value / 2;
		to_point.y = obj.rect.height.baseVal.value;   
		to_point = to_point.matrixTransform(obj.transform);
		target_point.x = target_x;
		target_point.y = target_y;
		target_point = target_point.matrixTransform(target_transform);

		mid = ((target_point.y - target_padding.top) -
		       (to_point.y + to_padding.bottom)) / target_count;
		mid = (mid * target_index) + (mid * (index + 1) / max_len);

		p2.x = to_point.x;
		p2.y = to_point.y + to_padding.bottom + mid;
		p3.x = target_point.x;
		p3.y = p2.y;
		line = polyline(to_point, p2, p3, target_point);
		obj.object.path_to = line;
		container.svg.append(line);
	    }

	    /*
	     * Finds the ancestor of inner that is a direct child of
	     * outer.  Then computes the top, left, bottom, and right
	     * values for the 'padding' (for lack of a better term)
	     * which is the distance from (for example) the top edge
	     * of the ancestor to the top edge of the inner element.
	     * All values are positive.
	     */
	    function find_padding(outer, inner) {
		var parent = inner;
		var new_parent;
		var transform;
		var parent_bbox;
		var inner_bbox;
		var o = {};

		while (true) {
		    new_parent = parent.parent();
		    if ((new_parent.length == 0) || (new_parent[0] == parent[0]))
			throw("Infinite loop");
		    if (new_parent[0] == outer)
			break;
		    parent = new_parent;
		}
		transform = inner[0].getTransformToElement(parent[0]);
		parent_bbox = parent[0].getBBox();
		inner_bbox = inner[0].getBBox();

		o.left = transform.e;
		o.top = transform.f;
		o.right = parent_bbox.width - transform.e - inner_bbox.width;
		o.bottom = parent_bbox.height - transform.f - inner_bbox.height;
		return o;
	    }

	    var svg = container.svg[0];
	    var target_rect = get_rect(target);;
	    var target_bbox = target_rect.getBBox();
	    /*
	     * The transform matrixes in this routine take a point at
	     * the corner of the outer element (svg in this case) and
	     * translate it to the position of the element itself
	     * (target_rect) in this case.  This is just how my brain
	     * works... Sorry.
	     */
	    var target_transform = target_rect.getTransformToElement(svg);
	    var target_point = svgElement.createSVGPoint();
	    var target_x;
	    var target_y;
	    var delta_x;
	    var to_point = svgElement.createSVGPoint();
	    var p2 = svgElement.createSVGPoint();
	    var p3 = svgElement.createSVGPoint();
	    var target_padding = find_padding(svg, target.svg);

	    /*
	     * above_target and below_target will be arrays of ent
	     * elements (both subsets of connections) that will be
	     * split into above or below based upon if their y
	     * position is above or below the target and then
	     * sorted based upon their x position.
	     *
	     * The elements inside will be objects with
	     * various properties that are needed during the
	     * process.
	     */
	    var above_target = [];
	    var below_target = [];
	    var below_left;
	    var below_right;
	    var above_left;
	    var above_right;
	    var max_len;

	    list.forEach(function (ent) {
		var to_rect = get_rect(ent);
		var to_bbox = to_rect.getBBox();
		var to_transform = to_rect.getTransformToElement(svg);
		var to_padding = find_padding(svg, ent.svg);

		var obj = {
		    object: ent,
		    rect: to_rect,
		    bbox: to_bbox,
		    transform: to_transform,
		    padding: to_padding
		};

		/*
		 * to_transform is starting from the target_rect
		 * (the target) and going to the
		 * to_rect (the ethernet adapter).  Thus a
		 * negative f value is when the ethernet
		 * adapter is below (further down the page)
		 * from the target.
		 */
		if (target_transform.f < to_transform.f)
		    below_target.push(obj);
		else
		    above_target.push(obj);
	    });

	    function compare(l, r) {
		return l.transform.e - r.transform.e;
	    };

	    below_target = below_target.sort(compare);
	    above_target = above_target.sort(compare);

	    target_x = 0;
	    delta_x = target_rect.width.baseVal.value / (below_target.length + 1);
	    target_y = target_rect.height.baseVal.value;
	    below_left = below_target.filter(function (obj, index) {
		return obj.transform.e < (target_transform.e + ((index + 1) * delta_x));
	    }, this);
	    below_right = below_target.slice(below_left.length);
	    max_len = Math.max(below_left.length, below_right.length) + 1;

	    below_left.forEach(draw_below_left);
	    below_right.forEach(draw_below_right);

	    target_x = 0;
	    delta_x = target_rect.width.baseVal.value / (above_target.length + 1);
	    target_y = 0;
	    above_left = above_target.filter(function (obj, index) {
		return obj.transform.e < (target_transform.e + ((index + 1) * delta_x));
	    }, this);
	    above_right = above_target.slice(above_left.length);
	    max_len = Math.max(above_left.length, above_right.length) + 1;

	    above_left.forEach(draw_above_left);
	    above_right.forEach(draw_above_right);
	}

	/**
	 * This is meant to be class other classes are built upon and
	 * implements a feature similar to padding of css.
	 * @constructor
	 */
	function Padding() {
	    if (this === window) {
		return new Padding();
	    }
	    return this;
	}

	Padding.prototype = {
	    /** @private */
	    _padding_top: 0,
	    /** @private */
	    _padding_right: 0,
	    /** @private */
	    _padding_bottom: 0,
	    /** @private */
	    _padding_left: 0,

	    /**
	     * The amount of space to add above the elements contained
	     * within the layout box.
	     * @type {Number}
	     */
	    get padding_top() { return this._padding_top; },
	    set padding_top(new_value) {
		this._padding_top = new_value;
		this.adjustLayout();
	    },

	    /**
	     * The amount of space to add above the elements contained
	     * within the layout box.
	     * @type {Number}
	     */
	    get padding_right() { return this._padding_right; },
	    set padding_right(new_value) {
		this._padding_right = new_value;
		this.adjustLayout();
	    },

	    /**
	     * The amount of space to add above the elements contained
	     * within the layout box.
	     * @type {Number}
	     */
	    get padding_bottom() { return this._padding_bottom; },
	    set padding_bottom(new_value) {
		this._padding_bottom = new_value;
		this.adjustLayout();
	    },

	    /**
	     * The amount of space to add above the elements contained
	     * within the layout box.
	     * @type {Number}
	     */
	    get padding_left() { return this._padding_left; },
	    set padding_left(new_value) {
		this._padding_left = new_value;
		this.adjustLayout();
	    },

	    /**
	     * The padding around the elements.  Tries to operate much
	     * like the css padding property.  Passing one value sets
	     * the top, right, bottom, and left padding attributes.
	     * Passing two sets top and bottom to the first and left
	     * and right to the second.  etc.
	     * @type {Array.<Number>}
	     */
	    set padding(not_used) {
		var new_value = arguments;

		if ((new_value.length == 1) && (new_value instanceof Array))
		    new_value = new_value[0];

		switch (new_value.length) {
		case 1:
		    this._padding_top =
			this._padding_right =
			this._padding_bottom =
			this._padding_left = new_value[0];
		    break;

		case 2:
		    this._padding_top =
			this._padding_bottom = new_value[0];
		    this._padding_right =
			this._padding_left = new_value[1];
		    break;

		case 3:
		    this._padding_top = new_value[0];
		    this._padding_right =
			this._padding_left = new_value[1];
		    this._padding_bottom = new_value[2];
		    break;

		case 4:
		    this._padding_top = new_value[0];
		    this._padding_right = new_value[1];
		    this._padding_bottom = new_value[2];
		    this._padding_left = new_value[3];
		    break;

		default:
		    throw('must pass 1, 2, 3, or 4 arguments');
		}
		this.adjustLayout();
		return this.padding;
	    },

	    get padding() {
		return [ this._padding_top,
			 this._padding_right,
			 this._padding_bottom,
			 this._padding_left ];
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.Padding = Padding;

	/**
	 * This creates a horizontal layout box that allows for easy
	 * horizontal layout of the items inside of it.  An SVG `g`
	 * element is created along with a `rect` element that is
	 * adjusted so that it surrounds the elements including
	 * padding on all four sides that can be adjusted.
	 *
	 * @constructor
	 * @param {Object} attrs - A set of attributes to set on the
	 * outer 'g' element.
	 * @extends Snapper~Padding
	 */
	function HLayoutBox(attrs) {
	    if (this === window) {
		return new HLayoutBox();
	    }

	    var horizontal_spacing = 0;

	    /**
	     * The horizontal spacing between the elements
	     * @member {Number} Snapper~HLayoutBox#horizontal_spacing
	     */
	    Object.defineProperty(this, 'horizontal_spacing', {
		get: function getHorizontalSpacing() {
		    return horizontal_spacing;
		},
		set: function setHorizontalSpacing(new_value) {
		    horizontal_spacing = new_value;
		    this.adjustLayout();
		}
	    });

	    /**
	     * The SVG tree for this layout box.
	     * @type {SVGTree}
	     */
	    this.svg = createElement('g');
	    if (attrs)
		this.svg.attr(attrs);
	    this.svg.data('HLayoutBox', this);

	    /**
	     * A rect that includes the elements as well as the
	     * padding.
	     */
	    this.rect = createElement('rect');
	    if (attrs && attrs.class)
		this.rect.attr('class', attrs.class);

	    this.svg.append(this.rect);

	    /**
	     * The elements added to the layout box
	     * @type {Array.<SVGTree>}
	     */
	    this.elements = [];

	    return this;
	}

	HLayoutBox.prototype = Object.create(Padding.prototype, {
	    /**
	     * Append in a horizontal fashion the obj with hSpacing
	     * between the previous element.
	     * @function
	     * @name Snapper~HLayoutBox#append
	     * @param {SVGTree} element - The element to append.
	     */
	    append: {
		value: function hLayoutBoxAppend(element, alignment) {
		    switch (alignment) {
		    case 'top':
		    case 'middle':
		    case 'bottom':
			break;
		    default:
			alignment = 'top';
			break;
		    }
		    this.elements.push({ element: element, alignment: alignment});
		    this.svg.append(element);
		    this.adjustLayout();
		    return this;
		}
	    },

	    /**
	     * Adjusts the layout of the elements as well as the
	     * surrounding rect.  There is usually no need to call
	     * this method because it is called from {@link
	     * Snapper~HLayout#append append} and also when the
	     * padding or horizontal spacing is changed.
	     * @function
	     * @name Snapper~HLayoutBox#adjustLayout
	     * @param {SVGTree} element - The element to append.
	     */
	    adjustLayout: {
		value: function hLayoutBoxAdjustLayout() {
		    var x = this.padding_left,
			y = this.padding_top,
			first = true,
			max_height = 0;

		    this.elements.forEach(function layoutElement(obj) {
			var element = obj.element;
			var bbox = element[0].getBBox();

			obj.bbox = bbox;
			if (max_height < bbox.height)
			    max_height = bbox.height;
		    });

		    this.elements.forEach(function layoutElement(obj) {
			var element = obj.element;
			var bbox = obj.bbox;
			var delta_y;
		
			if (first) {
			    first = false;
			} else {
			    x += this.horizontal_spacing;
			}

			switch (obj.alignment) {
			case 'top':
			    delta_y = 0;
			    break;

			case 'middle':
			    delta_y = (max_height - bbox.height) / 2;
			    break;

			case 'bottom':
			    delta_y = (max_height - bbox.height);
			    break;
			}

			element.attr({ transform: translate(x, y + delta_y) });
			x += bbox.width;
		    }, this);
		    x += this.padding_right;
		    y += max_height + this.padding_bottom;
		    this.rect.attr({ width: x, height: y });
		}
	    }
	});

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.HLayoutBox = HLayoutBox;


	/**
	 * This creates a vertical layout box that allows for easy
	 * vertical layout of the items inside of it.  Very often, a
	 * vLayoutBox is used to contain a set of HLayoutBoxes.  An
	 * SVG `g` element is created along with a `rect` element that
	 * is adjusted so that it surrounds the elements including
	 * padding on all four sides that can be adjusted.
	 *
	 * @constructor
	 * @param {Object} attrs - A set of attributes to set on the
	 * outer 'g' element.
	 * @extends Snapper~Padding
	 */
	function VLayoutBox(attrs) {
	    if (this === window) {
		return new VLayoutBox();
	    }

	    var vertical_spacing = 0;

	    /**
	     * The vertical spacing between the elements
	     * @member {Number} Snapper~VLayoutBox#vertical_spacing
	     */
	    Object.defineProperty(this, 'vertical_spacing', {
		get: function getVerticalSpacing() {
		    return vertical_spacing;
		},
		set: function setVerticalSpacing(new_value) {
		    vertical_spacing = new_value;
		    this.adjustLayout();
		}
	    });

	    /**
	     * The SVG tree for this layout box.
	     * @type {SVGTree}
	     */
	    this.svg = createElement('g');
	    if (attrs)
		this.svg.attr(attrs);
	    this.svg.data('VLayoutBox', this);

	    /**
	     * A rect that includes the elements as well as the
	     * padding.
	     */
	    this.rect = createElement('rect');
	    if (attrs && attrs.class)
		this.rect.attr('class', attrs.class);

	    this.svg.append(this.rect);

	    /**
	     * The elements added to the layout box
	     * @type {Array.<SVGTree>}
	     */
	    this.elements = [];

	    return this;
	}

	VLayoutBox.prototype = Object.create(Padding.prototype, {
	    /**
	     * Append in a vertical fashion the obj with hSpacing
	     * between the previous element.
	     * @function
	     * @name Snapper~VLayoutBox#append
	     * @param {SVGTree} element - The element to append.
	     */
	    append: {
		value: function vLayoutBoxAppend(element, alignment) {
		    switch (alignment) {
		    case 'left':
		    case 'middle':
		    case 'right':
			break;
		    default:
			alignment = 'left';
			break;
		    }

		    this.elements.push({ element: element, alignment: alignment });
		    this.svg.append(element);
		    this.adjustLayout();
		    return this;
		}
	    },

	    /**
	     * Adjusts the layout of the elements as well as the
	     * surrounding rect.  There is usually no need to call
	     * this method because it is called from {@link
	     * Snapper~VLayout#append append} and also when the
	     * padding or vertical spacing is changed.
	     * @function
	     * @name Snapper~VLayoutBox#adjustLayout
	     * @param {SVGTree} element - The element to append.
	     */
	    adjustLayout: {
		value: function vLayoutBoxAdjustLayout() {
		    var x = this.padding_left,
			y = this.padding_top,
			first = true,
			max_width = 0;
	    
		    this.elements.forEach(function layoutElement(obj) {
			var element = obj.element;
			var bbox = element[0].getBBox();

			obj.bbox = bbox;
			if (max_width < bbox.width)
			    max_width = bbox.width;
		    });

		    this.elements.forEach(function layoutElement(obj) {
			var element = obj.element;
			var bbox = obj.bbox;
			var delta_x;
		
			if (first) {
			    first = false;
			} else {
			    y += this.vertical_spacing;
			}

			switch (obj.alignment) {
			case 'left':
			    delta_x = 0;
			    break;

			case 'middle':
			    delta_x = (max_width - bbox.width) / 2;
			    break;

			case 'right':
			    delta_x = (max_width - bbox.width);
			    break;
			}

			element.attr({ transform: translate(x + delta_x, y) });
			y += bbox.height;
			if (max_width < bbox.width)
			    max_width = bbox.width;
		    }, this);
		    x += max_width + this.padding_right;
		    y += this.padding_bottom;
		    this.rect.attr({ width: x, height: y });
		}
	    }
	});

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.VLayoutBox = VLayoutBox;

	/**
	 * Creates a World
	 * @constructor
	 *
	 * @classdesc World is a container that will hold everything
	 * known to Snapper which includes CECs and later on external
	 * switches and perhaps other concepts such as VPN links, etc.
	 */
	function World() {
	    if (this === window) {
		return new World();
	    }

	    /**
	     * The id of the world which is always "World".
	     * @type {String}
	     * @default
	     */
	    this.id = "World";

	    /**
	     * The name of the world which is always "World".
	     * @type {String}
	     * @default
	     */
	    this.name = "World";
	     
	    /**
	     * The CECs known in this world.
	     * @type {Object.<SystemId, Snapper~CEC>}
	     */
	    this.cecs = {};

	    /**
	     * The array of snaps that have been passed to this world
	     * via the {@link Snapper~World#addSnap addSnap} method.
	     * @type {Array.<Snap>}
	     */
	    this.snaps = [];

	    /**
	     * This array is for the {@link Batch}es that are added.
	     * Currently the ruby code can only add one batch
	     */
	    this.batches = [];
	    return this;
	}

	World.prototype = {
	    /**
	     * The padding in pixels to put around the world when it is
	     * drawn.
	     * @constant {Number}
	     * @default
	     */
	    padding: 5,

	    /**
	     * Eventually, this will need to create the interconnects
	     * between the CECs and the external switches, routers,
	     * tunnels, etc.
	     *
	     * The createInterconnects methods are called after the tree
	     * of svg nodes has been put into the DOM.  This allows
	     * getBBox and other methods to be called.
	     */
	    createInterconnects: function createInterconnectsForWorld() {
		Object.getOwnPropertyNames(this.cecs).forEach(function callCECCreateInterconnect(id) {
		    this.cecs[id].createInterconnects();
		}, this);
	    },

	    /**
	     * draws the world calling {@link Snapper~render render}
	     * with the {@link Snapper~World#cecs CECs} known to this
	     * world and placing them into an SVG group element with
	     * `id` of `World` and `class` of `world`.
	     * @return {SVGTree}
	     */
	    draw: function drawForWorld() {
		var x = this.padding, y = this.padding;
		var layout = new HLayoutBox({ id: this.id, class: 'world' });
		layout.padding = this.padding;
		layout.horizontal_spacing = 20;

		render(this.cecs).forEach(function add(cec_svg) {
		    layout.append(cec_svg);
		});

		// I bet this is not precisely correct.  It works
		// because right and top are zero.  But if they were
		// not zero, I bet I need to make some type of
		// adjustment of the clipping rectangle.
		svgSelection.attr({
		    width: parseInt(layout.rect.attr('width')) +
			parseInt($('body').css('margin-right')),
		    height: parseInt(layout.rect.attr('height')) +
			parseInt($('body').css('margin-top'))
		});

		/**
		 * The SVG tree for the World
		 * @type {SVGTree}
		 */
		this.svg = layout.svg;
		this.svg.data('World', this);
		$('svg').append(this.svg);
	    },

	    /**
	     * {@link Batch} is defined in the Ruby code.  We ignore the
	     * alerts for now and walk the snap_list.  The snap_list
	     * is a list of {@link Snap}s that we will add via {@link
	     * Snapper~World#addSnap addSnap}.  This method is called
	     * by the javascript code created by <a
	     * href='../ruby/Page.html#method-i-add_data'>Page#add_data</a>.
	     *
	     * @param {Batch} batch
	     */
	    addBatch: function addBatchToWorld(batch) {
		var that = this;
		function func() {
		    batch.snap_list.forEach(World.prototype.addSnap, that);
		    window.snapper.world.draw();
		    window.snapper.world.createInterconnects();
		};

		if ($.isReady) {
		    func();
		} else {
		    $(document).ready(func);
		}
	    },

	    /**
	     * Adds a {@link Snap} to the list of snaps and causes the
	     * values of the snap to be merged into the world.  The
	     * 'id_to_system' of the 'sys0' elemeent of the 'CuAt'
	     * element in the data (e.g. snap.cu_at.sys0.id_to_system)
	     * is used to determine the name of the CEC.  A {@link
	     * Snapper~CEC CEC} is created and its {@link
	     * Snapper~CEC#addSnap addSnap} method is called with the
	     * same data passed into this function.
	     *
	     * @param {Snap} snap - Output from the snapper Ruby
	     * code in the form.
	     */
	    addSnap: function addSnapToWorld(snap) {
		/* Mostly for debugging purposes */
		this.snaps.push(snap);

		var system_id = snap.db.hostname.id_to_system;
		if (typeof system_id === 'undefined' || system_id == "") {
		    alert("World.addSnap: id_to_system is either undefined or the empty string");
		    return;
		}

		if (typeof this.cecs[system_id] === 'undefined')
		    this.cecs[system_id] = new CEC(this, system_id);
		this.cecs[system_id].addSnap(snap);
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.World = World;

	/**
	 * A CEC is a physical box with its own id_to_system.  It is
	 * created empty and LPARs are added to it by calling its
	 * {@link Snapper~CEC#addSnap addSnap} function.
	 *
	 * @constructor
	 * @param {World} world - The world to which this CEC belongs.
	 * @param {String} id - The id of this CEC
	 */
	function CEC(world, id) {
	    if (this === window) {
		return new CEC(world, id);
	    }

	    /**
	     * Reference back to the world that containts this CEC.
	     * @type {World}
	     */
	    this.world = world;

	    /**
	     * The id_to_system value for this CEC.
	     * @type {SystemId}
	     */
	    this.id = id;

	    /**
	     * The name of the CEC which is currently the same as the
	     * id_to_system.
	     * @type {String}
	     */
	    this.name = id;

	    /**
	     * The values passed to the {@link Snapper~CEC#addSnap
	     * addSnap} method.
	     * @type {Array.<Snap>}
	     */
	    this.snaps = [];

	    /**
	     * The array of {@link Snapper~LPAR LPARs} within this
	     * CEC.
	     * @type {Array.<Snapper~LPAR>}
	     */
	    this.lpars = {};

	    /**
	     * The array of {@link Snapper~VirtualSwitch virtual
	     * switches} within this CEC.
	     * @type {(undefined|Object.<String,Snapper~VirtualSwitch>)}
	     */
	    this.virtual_switches = undefined;
	    return this;
	}

	CEC.prototype = {
	    /**
	     * The horizontal spacing between LPARs
	     * @constant {Number}
	     * @default
	     */
	    hSpacing: 25,

	    /**
	     * The vertical spacing between LPARs.
	     * @constant {Number}
	     * @default
	     */
	    vSpacing: 100,

	    /**
	     * The padding around each CEC
	     * @constant {Number}
	     * @default
	     */
	    padding: 10,

	    /**
	     * Creates the interconnections within the CEC but outside
	     * or between any LPARs and also calls the {@link
	     * Snapper~LPAR#createInterconnects createInterconnects}
	     * method for each LPAR.
	     */
	    createInterconnects: function createInterconnectsForCEC() {
		Object.getOwnPropertyNames(this.lpars).forEach(function (id) {
		    this.lpars[id].createInterconnects();
		}, this);

		/*
		 * I'm going to try and make this as generic as
		 * possible so it might be used other places.
		 */
		if (this.virtual_switches)
		    Object.getOwnPropertyNames(this.virtual_switches).forEach(function (virtual_switch_name, index, names) {
			var virtual_switch = this.virtual_switches[virtual_switch_name];

			connectListToTarget(this, virtual_switch, virtual_switch.connections, index, names.length);
		    }, this);
	    },

	    /**
	     * draws the CEC by calling {@link Snapper~render render}
	     * with {@link Snapper~CEC#lpars lpars} and placing them
	     * into a group element with an `id` of the CEC's {@link
	     * Snapper~CEC#name name} and a `class` of `cec`.
	     * @return {SVGTree}
	     */
	    draw: function drawForCEC() {
		var layout = new VLayoutBox({ id: this.id, class: 'cec' });
		var vios_layout_box = undefined;
		var non_vios_layout_box = undefined;
		var virtual_switch_layout_box = undefined;

		/* put virtual switches into their own layout box */
		if (this.virtual_switches) {
		    virtual_switch_layout_box = new HLayoutBox({ class: 'virtual-switch-layout-box' });
		    render(this.virtual_switches).forEach(function (vswitch)  {
			virtual_switch_layout_box.append(vswitch);
		    }, this);
		}

		/* put LPARs into one of two layout boxes */
		Object.getOwnPropertyNames(this.lpars).forEach(function (id) {
		    var lpar = this.lpars[id];

		    if (lpar.isVIOS()) {
			if (vios_layout_box === undefined)
			    vios_layout_box = new HLayoutBox({ class: 'vios-layout-box' });
			vios_layout_box.append(lpar.draw());
		    } else {
			if (non_vios_layout_box === undefined)
			    non_vios_layout_box = new HLayoutBox({ class: 'non-vios-layout-box' });
			non_vios_layout_box.append(lpar.draw());
		    }
		}, this);

		/* Put the three boxes into the virtual box */
		[ non_vios_layout_box,
		  virtual_switch_layout_box,
		  vios_layout_box ].forEach(function (box) {
		      if (box) {
			  box.horizontal_spacing = this.hSpacing;
			  layout.append(box.svg, 'middle');
		      }
		  }, this);
		layout.padding = this.padding;
		layout.vertical_spacing = this.vSpacing;

		/**
		 * The SVG tree for this CEC.
		 * @type {SVGTree}
		 */
		this.svg = layout.svg;
		this.svg.data('CEC', this);
		return this.svg;
	    },

	    /**
	     * Called via {@link Snapper~World#addSnap} it will create
	     * a new {@link Snapper~LPAR LPAR} with the data passed
	     * in.  This may change to create a new LPAR only when
	     * needed and add an addSnap method to LPAR so that
	     * multiple sets of data can be added to a single LPAR if
	     * needed.
	     * @param {Snap} snap - The data from the snap for this
	     * CEC.
	     */
	    addSnap: function (snap) {
		/* Again... mostly for debugging purposes */
		this.snaps.push(snap);

		var partition_id = snap.db.hostname.id_to_partition;
		if (typeof partition_id === 'undefined' || partition_id == "") {
		    alert("CEC.addSnap: id_to_partition is either undefined or the empty string");
		    return;
		}

		if (typeof this.lpars[partition_id] === 'undefined')
		    this.lpars[partition_id] = new LPAR(this, partition_id, snap);
		else
		    alert("CEC.addSnap: attempt to redefine partition " + partition_id + " within CEC " + this.id);
	    },

	    /**
	     *
	     * Creates a virtual switch if necessary and returns the
	     * {@link VirtualSwitch virtual switch} instance.
	     *
	     * @param {String} id - The id for the virtual switch.
	     */
	    getVirtualSwitch: function getVirtualSwitch(id, vea) {
		if (this.virtual_switches == undefined) {
		    this.virtual_switches = {};
		}
		if (typeof this.virtual_switches[id] === 'undefined') {
		    this.virtual_switches[id] = new VirtualSwitch(this, id);
		}
		this.virtual_switches[id].addConnection(vea);
		return this.virtual_switches[id];
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.CEC = CEC;

	/**
	 * Represents an LPAR
	 * @constructor
	 * @param {CEC} cec - The CEC that the LPAR belongs to.
	 * @param {PartitionId} id - The partition id for this LPAR
	 * @param {Snap} snap - The snap data for this LPAR
	 */
	function LPAR(cec, id, snap) {
	    if (this === window) {
		return new LPAR(cec, id);
	    }

	    /**
	     * Reference to the CEC that this LPAR is a part of.
	     * @type {CEC}
	     */
	    this.cec = cec;

	    /**
	     * The partition id for this LPAR.  This is unique to the
	     * world.
	     * @type {PartitionId}
	     */
	    this.id = id;

	    /**
	     * The data from the snap taken on this LPAR
	     * @type {Snap}
	     */
	    this.snap = snap;

	    /**
	     * Each Object is a stanza from the CuAt odm database.
	     * @type {Array.<Object>}
	     */
	    this.cu_at = snap.db.cu_at;

	    /**
	     * Each Object is a stanza from the CuDv odm database.
	     * @type {Array.<Object>}
	     */
	    this.cu_dv = snap.db.cu_dv;

	    /**
	     * Each Object is a stanza from the PdAt odm database.
	     * Remember that some snaps do not have PdAt so this may
	     * be undefined.
	     * @type {Array.<Object>}
	     */
	    this.pd_at = snap.db.pd_at;

	    /**
	     * Each Object is a stanza from the PdDv odm database.
	     * Remember, this may be undefined since some snaps do not
	     * have the predefined entries of the ODM database.
	     * @type {Array.<Object>}
	     */
	    this.pd_dv = snap.db.pd_dv;

	    /**
	     * An object with two elements: <dl>
	     * <dt>`byName`</dt><dd>{@link Snapper~Device Devices}
	     * indexed by their logical name</dd>
	     * <dt>`byType`</dt><dd>{@link Snapper~Device Devices}
	     * indexed by the PdDvLn attribute which is also called
	     * uniquetype in other ODM tables such as CuAt and
	     * CuDv.</dd> </dl>
	     * @type {Object}
	     */
	    this.devices = {
	    	/**
	    	 * Devices indexed by the logical name
	    	 * @type {Object.<DeviceName, Snapper~Device>}
	    	 */
	    	byName: {},

	    	/**
	    	 * Devices indexed by the PdDvLn which is also called
	    	 * uniquetype in other ODM classes such as CuAt and
	    	 * CuDv.
	    	 * @type {Object.<DeviceName, Snapper~Device>}
	    	 */
	    	byType: {}
	    };

	    Object.keys(snap.db.devices).forEach(function (name) {
		var device = snap.db.devices[name];
		if (device.pd_dv) {
		    var newDevice = new Device(this.lpar, device, this.snap);
		    var thisType = this.devices.byType[device.cu_dv.pd_dv_ln];

		    this.devices.byName[device.cu_dv.name] = newDevice;
	    	    if (typeof thisType === 'undefined')
	    		thisType = (this.devices.byType[device.cu_dv.pd_dv_ln] = []);
	    	    thisType.push(newDevice);
		}
	    }, this);

	    /**
	     * The hostname of the LPAR comes from the `hostname`
	     * attribute of the `inet0` stanza.
	     * @type {String}
	     */
	    this.hostname = snap.db.hostname.node_name;

	    /**
	     * The name of the LPAR is set equal to the hostname.
	     * @type {String}
	     */
	    this.name = this.hostname;

	    /**
	     * An array of SEAs (if any) present in this LPAR.
	     * @type {(undefined|Array.<Snapper~SEA>)}
	     */
	    if (this.devices.byType['adapter/pseudo/sea']) {
	    	this.seas = this.devices.byType['adapter/pseudo/sea'].map(function (device) {
	    	    return new SEA(this, device);
	    	}, this);
	    }

	    /**
	     * The ifnets within the LPAR.  we find all of the
	     * if/EN/en (which ignores token ring and all other types
	     * of ifnets) which have a customized netaddr.
	     * @type {Array.<Snapper~Ifnet>}
	     */

	    this.ifnets = Object.keys(snap.db.interfaces).filter(function (ifnet_name) {
		return (this.devices.byName[ifnet_name] && ifnet_name != "lo0");
	    }, this).map(function (ifnet_name) {
		return new Ifnet(this, this.devices.byName[ifnet_name]);
	    }, this);

	    /**
	     * We run through ifnets and filter out the SEAs and are
	     * left with non-SEA adapters with an ifnet.
	     * @type {Array.<Snapper~Ent|Snapper-EthChan>}
	     */
	    this.adapters = this.ifnets.filter(function (ifnet) {
	    	return !(ifnet.adapter.isSEA());
	    }).map(function (ifnet) {
	    	var ent;

	    	if (ifnet.adapter.isEthChan())
	    	    ent = new EthChan(this, ifnet.adapter);
	    	else
	    	    ent = new Ent(this, ifnet.adapter);
	    	ent.ifnet = ifnet;
	    	return ent;
	    }, this);
	    return this;
	}
	
	LPAR.prototype = {
	    /**
	     * The horizontal spacing between LPARs
	     * @constant {Number}
	     * @default
	     */
	    hSpacing: 25,

	    /**
	     * The vertical spacing between LPARs.
	     * @constant {Number}
	     * @default
	     */
	    vSpacing: 50,

	    /**
	     * The padding around each CEC
	     * @constant {Number}
	     * @default
	     */
	    padding: 10,

	    /**
	     * Calls {@link Snapper~SEA#createInterconnects
	     * createInterconnects} for each SEA and then creates the
	     * interconnects from the ifnets to their adapter.
	     */
	    createInterconnects: function createInterconnectsForLPAR() {
		if (this.seas) {
		    this.seas.forEach(function (sea) {
			sea.createInterconnects();
		    });
		}
		if (this.ifnets)
		    this.ifnets.forEach(function (ifnet) {
			var p1 = svgElement.createSVGPoint();
			var p2 = svgElement.createSVGPoint();
			var p3 = svgElement.createSVGPoint();
			var adapterSVG;
			var lparSVG;
			var adapterBBox;
			var ifnetSVG = ifnet.svg;
			var ifnetBBox = ifnetSVG[0].getBBox();

			if (!ifnet.adapter.isSEA())
			    return;
			adapterSVG = ifnet.adapter.ent.svg;
			adapterBBox = adapterSVG[0].getBBox();
			lparSVG = this.svg[0];

			p1 = p1.matrixTransform(adapterSVG[0].getTransformToElement(lparSVG));
			p1.x -= ((2 * SEA.prototype.padding) + (ifnetBBox.width));
			p1.y += (adapterBBox.height / 2) - (2 * SEA.prototype.padding) - ifnetBBox.height;
			ifnetSVG.attr({ transform: translate(p1.x, p1.y) });

			// move p1 to point of ifnet
			p1.x += ifnetBBox.width / 2;
			p1.y += ifnetBBox.height;

			// find p3 -- middle of left edge of adapter
			p3.x = 0;
			p3.y = adapterBBox.height / 2;
			p3 = p3.matrixTransform(adapterSVG[0].getTransformToElement(lparSVG));

			// p2 is down from p1
			p2.x = p1.x;
			p2.y = p3.y;
			this.svg.append(polyline(p1, p2, p3));
		    }, this);
	    },

	    /**
	     * Calls {@link Snapper~render render} with {@link
	     * Snapper~LPAR#seas seas} then calls {@link
	     * Snapper~render render} with {@link
	     * Snapper~LPAR#adapters} and also renders the ifnets
	     * for those adapters.  All of these are put into a group
	     * element with an `id` of the LPAR's {@link
	     * Snapper~LPAR#name name} and a `class` of `lpar`.
	     * @return {SVGTree}
	     */
	    draw: function drawForLPAR() {
		var x = this.padding, y = this.padding;
		var g = createElement('g').attr({
		    id: this.id,
		    class: 'lpar'
		});
		var height = 0;
		var rect = createElement('rect').attr({
		    class: 'lpar'
		});
		var name_plate = createElement('text')
			.attr('class', 'name-plate')
			.append(this.name);
		var name_bbox = name_plate[0].getBBox();

		g.append(rect);

		// render the SEAs and the associated ifnet if any
		if (this.seas) {
		    this.rendered_seas = render(this.seas).forEach(function (seaSVG, index) {
			var sea = this.seas[index];
			var seaBBox = seaSVG[0].getBBox();
			var ifnetBBox;
			
			// Ifnets go on the left
			this.ifnets.forEach(function (ifnet) {
			    if (ifnet.adapter === sea.device) {
				sea.rendered_ifnet = ifnet.draw();
				ifnetBBox = sea.rendered_ifnet[0].getBBox();
				// Can't place it until the createInterconnects phase
				g.append(sea.rendered_ifnet);
				x += ifnetBBox.width + SEA.prototype.padding;
			    }
			}, this);
			g.append(seaSVG.attr({ transform: translate(x, y) }));
			if (height < seaBBox.height)
			    height = seaBBox.height;
			x += seaBBox.width + this.hSpacing;
			// Check for ifnet
		    }, this);
		} else {
		    /* non-VIOS has name at the top */
		    y += name_bbox.height + 2;
		}

		// render the non-SEA adapters and their ifnets
		this.rendered_adapters = render(this.adapters).forEach(function (adapterSVG, index) {
		    var adapter = this.adapters[index];
		    var adapterBBox = adapterSVG[0].getBBox();
		    var ifnetBBox;
		    var ifnet_y;
		    var ifnet_x;
		    var adapter_y;
		    var adapter_x;
		    var half_adapter_height = adapterBBox.height / 2;
		    var temp_height;
		    var p1 = svgElement.createSVGPoint();
		    var p2 = svgElement.createSVGPoint();
		    var p3 = svgElement.createSVGPoint();

		    adapter.rendered_ifnet = adapter.ifnet.draw();
		    ifnetBBox = adapter.rendered_ifnet[0].getBBox();
		    temp_height = ifnetBBox.height + (2 * SEA.prototype.padding);
		    if (half_adapter_height > temp_height)
			temp_height = adapterBBox.height;
		    else
			temp_height += half_adapter_height;
		    if (height < temp_height)
			height = temp_height;

		    ifnet_x = x;
		    ifnet_y = y + height - half_adapter_height - ifnetBBox.height - (SEA.prototype.padding * 2);
		    g.append(adapter.rendered_ifnet.attr({ transform: translate(ifnet_x, ifnet_y) }));
		    x += ifnetBBox.width + (SEA.prototype.padding * 2);
		    p1.x = ifnet_x + (ifnetBBox.width / 2);
		    p1.y = ifnet_y + ifnetBBox.height;

		    adapter_x = x;
		    adapter_y = y + height - adapterBBox.height;
		    g.append(adapterSVG.attr({ transform: translate(adapter_x, adapter_y) }));
		    x += adapterBBox.width + this.hSpacing;
		    p3.x = adapter_x;
		    p3.y = adapter_y + half_adapter_height;

		    p2.x = p1.x;
		    p2.y = p3.y;
		    g.append(polyline(p1, p2, p3));
		}, this);

		height += (2 * this.padding) + name_bbox.height + 2;
		x += (this.padding - this.hSpacing);
		rect.attr({
		    width: x,
		    height: height
		});

		if (this.seas)
		    name_plate.attr('y', height - name_bbox.height - name_bbox.y);
		else
		    name_plate.attr('y', -(name_bbox.y - 1));
		name_plate.attr('x', x / 2);
		g.append(name_plate);

		/**
		 * The SVG tree for this LPAR
		 * @type {SVGTree}
		 */
		this.svg = g;
		this.svg.data('LPAR', this);
		return g;
	    },

	    /**
	     * Returns true if the LPAR is a VIOS.  This is currently
	     * true if the LPAR have any SEAs.
	     * @return {Boolean}
	     */
	    isVIOS: function lparIsVIOS() {
		return this.seas !== undefined;
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.LPAR = LPAR;

	/**
	 * The Ifnet class represents the ifnets such as en0.
	 * "interface" is reserved in Javascript so I went with
	 * Ifnet.
	 * @constructor
	 * @param {Snapper~LPAR} lpar - The LPAR the ifnet belongs to.
	 * @param {Snapper~Device} device - The Device description.
	 */
	function Ifnet(lpar, device) {
	    if (this === window) {
		return new Ifnet(lpar, device);
	    }

	    /**
	     * Reference back to the containing LPAR.
	     * @type {Snapper~LPAR}
	     */
	    this.lpar = lpar;

	    /**
	     * The id of the ifnet which is the lpar name plus the
	     * ifnet name.
	     * @tyep {String}
	     */
	    this.id = lpar.name + '-' + device.name;

	    /**
	     * The name such as en0 or en5.
	     * @type {String}
	     */
	    this.name = device.name;

	    /**
	     * The Device entry for this ifnet.
	     * @type {Snapper~Device}
	     */
	    this.device = device;

	    device.ifnet = this;

	    /**
	     * The adapter that the ifnet is sitting on top of.
	     * @type {Snapper~Device}
	     */
	    this.adapter = lpar.devices.byName[device.name.replace(/e[nt]/, 'ent')];
	    return this;
	}

	Ifnet.prototype = {
	    /**
	     * The ifnet is represented by an equilateral
	     * triangle.  Each side is this size (in pixels).
	     * @constant {Number}
	     * @default
	     */
	    side: 40,

	    /**
	     * A null routine.
	     */
	    createInterconnects: function createInterconnectsForIfnet() {
	    },

	    /**
	     * Draws the ifnet with the name of the ifnet
	     * embeded and places those items into an SVG group
	     * element with an `id` of the ifnet's {@link
	     * Snapper~Ifnet#name name} and a `class` of `ifnet`.
	     * @return {SVGTree}
	     */
	    draw: function drawForIfnet() {
		var mid = this.side / 2;
		var height = Math.sqrt((mid * mid) + (this.side * this.side));
		var g = createElement('g').attr({
		    id: this.id,
		    class: 'ifnet'
		}).append(polyline({ x: 0, y: 0 }, { x: this.side, y: 0 }, { x: mid, y: height }).attr({
		    class: 'ifnet'
		})).append(createElement('text').attr({
		    x: this.side / 2,
		    y: this.side / 2
		}).append(this.name));
		
		/**
		 * A jQuery object for the SVG group that represents
		 * this ifnet
		 * @type {SVGTree}
		 */
		this.svg = g;
		this.svg.data('Ifnet', this);
		return g;
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.Ifnet = Ifnet;

	/**
	 * A Device is a common place gathers common attributes and
	 * methods together.
	 *
	 * As other objects are created using this device, they hook
	 * themselves in using an obvious name.  e.g. when an Ent is
	 * created, it hooks in as device.ent.  When a SEA is created,
	 * it hooks in as device.sea.  A direct svg element is not
	 * saved because it is ambiguous.
	 *
	 * Note that the Ruby code also has a Device that is dumped
	 * out as JSON and comes in to the Javascript via addSnap
	 * under snap.db.devices.
	 *
	 * The original code keyed off of the CuDv entry so you may
	 * still find some oddness in the code and comments.
	 * @constructor
	 * @param {Snapper~LPAR} lpar - The LPAR that this Device will
	 * be a part of.
	 * @param {RubyDevice} device - The Ruby devices entry for this
	 * device.
	 * @param {Snap} snap - The snap data.
	 */
	function Device(lpar, device, snap) {
	    if (this === window) {
		return new Device(lpar, device, snap);
	    }

	    var cu_dv = device.cu_dv;
	    var uniquetype = device.pd_dv.uniquetype;
	    var name = device.name;

	    /**
	     * The LPAR that this device is a part of.
	     * @type {Snapper~LPAR}
	     */
	    this.lpar = lpar;

	    /**
	     * The device entry for this device.
	     * @type {Object}
	     */
	    this.hash = device;

	    /**
	     * The CuDv entry for this device.
	     * @type {Object}
	     */
	    this.cu_dv = cu_dv;

	    /**
	     * The rest of the snap from the LPAR.  This probably
	     * should not be saved here.
	     */
	    this.snap = snap;

	    /**
	     * The `name` field taken from the {@link
	     * Snapper~Device#cu_dv CuDv} entry.
	     * @type {String}
	     */
	    this.name = name;

	    /**
	     * The `uniquetype` field taken from the {@link
	     * Snapper~Device#cu_dv CuDv} entry.
	     * @type {String}
	     */
	    this.uniquetype = uniquetype;

	    /**
	     * The corresponding PdDv (predefined Device) entry for
	     * this device.  Note that this may be null in the case
	     * that the predefined ODM files were not gathered.
	     * @type {Object}
	     */
	    this.pd_dv = device.pd_dv;

	    /**
	     * The array of PdAt (predefined attributes) for this
	     * device entry.  Note that this may be null in the case
	     * that the predefined ODM files were not gathered.
	     * @type {Array.<Object>}
	     */
	    this.pd_at = device.pd_at;

	    /**
	     * The array of CuAt (customized attributes) for this
	     * device entry.
	     * @type {Array.<Object>}
	     */
	    this.cu_at = device.cu_at;

	    /**
	     * The attributes stored by the attribute name for this
	     * device. Each element is an Object with two
	     * attributes:<dl>
	     * <dt>`pd_at`</dt><dd>The PdAt entry for this
	     * attribute.<dd>
	     * <dt>`values`</dt><dd>An array of CuAt entries (very
	     * often only one) for this attribute (for this
	     * device)</dd>
	     * </dl>
	     */
	    this.attributes = {};
	    Object.keys(device.attributes).forEach(function (attr, index, keys) {
		var temp = device.attributes[attr];
		/* attributes was an Item so it has other things like text */
		if (typeof temp.cu_ats === "undefined")
		    return;
		this.attributes[attr] = new Attribute(temp.cu_ats, temp.pd_ats);
	    }, this);

	    this.attrs = device.attrs;

	    // /* Set up an attribute for each PdAt entry -- 
	    //  * should be only one PdAt entry per attribute */
	    // this.pd_at.forEach(function (pd_at) {
	    // 	this.attributes[pd_at['attribute']] = {
	    // 	    pd_at: pd_at,
	    // 	    values: []
	    // 	};
	    // }, this);
	    // /* Now fill in values array from customized attributes */
	    // this.cu_at.forEach(function (cu_at) {
	    // 	var attribute = this.attributes[cu_at['attribute']];
	    // 	if (typeof attribute === 'undefined') // rare but it does happen
	    // 	    attribute = (this.attributes[cu_at['attribute']] = { values: [] });
	    // 	attribute.values.push(cu_at);
	    // }, this);

	    /**
	     * @type {Snapper~Ifnet}
	     */
	    this.ifnet = undefined;

	    /**
	     * @type {Snapper~SEA}
	     */
	    this.sea = undefined;

	    /**
	     * @type {Snapper~EthChan}
	     */
	    this.ethchan = undefined;
	    return this;
	}

	Device.prototype = {
	    /** Returns true if the device is a SEA */
	    isSEA: function () {
		return this.cu_dv['ddins'] === "seadd";
	    },

	    /** Returns true if the device is an etherchannel */
	    isEthChan: function () {
		return this.cu_dv['ddins'] === "ethchandd";
	    },

	    /** Returns true if the device is a virtual ethernet
	     * adapter */
	    isVEA: function () {
		return this.cu_dv.ddins === "vioentdd";
	    },

	    /** Returns true if the device is an ethernet adapter */
	    isEnt: function () {
		return this.cu_dv['name'].slice(0,3) === "ent";
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.Device = Device;

	/**
	 * Represents a Shared Ethernet Adapter.
	 * @constructor
	 * @param {Snapper~LPAR} lpar - The LPAR that contains this
	 * SEA.
	 * @param {Snapper~Device} device - The Device entry for this
	 * SEA.
	 */
	function SEA(lpar, device) {
	    if (this === window) {
		return new SEA(lpar, device);
	    }

	    /**
	     * The name of the SEA.  Currently it is taken from the
	     * device's name.
	     * @type {String}
	     */
	    this.name = device.name;

	    /**
	     * The LPAR that contains this SEA.
	     * @type {Snapper~LPAR}
	     */
	    this.lpar = lpar;

	    /**
	     * The Device entry for this SEA.
	     * @type {Snapper~Device}
	     */
	    this.device = device;
	    device.sea = this;

	    /**
	     * The ethernet adapter for this SEA.
	     * @type {Snapper~Ent}
	     */
	    this.ent = new Ent(lpar, device);

	    /**
	     * The ethernet adapter used as the control channel for
	     * this SEA.
	     * @member {Snapper~Ent} Snapper~SEA#ctl_chan
	     */

	    /**
	     * The list of virtual adapters used by this SEA.
	     * @member {Snapper~Ent} Snapper~SEA#virt_adapters
	     */

	    /**
	     * The ethernet adapter used as the real adapter for this
	     * SEA.
	     * @member {(Snapper~Ent|Snapper~EthChan)} Snapper~SEA#real_adapter
	     */
	    [ 'ctl_chan', 'real_adapter', 'virt_adapters' ].forEach(function (attr) {
		var value = device.attributes[attr].value;

		this[attr] = value.split(',').map(function (devName) {
		    var device = this.lpar.devices.byName[devName];
		    if (typeof device === 'undefined')
			alert("SEA ctor: device " + devName + " not found in parent LPAR " + lpar.name);
		    if (device.isEthChan()) {
			return new EthChan(this.lpar, device);
		    } else {
			return new Ent(this.lpar, device);
		    }
		}, this);
	    }, this);

	    this.ctl_chan = this.ctl_chan[0];
	    this.real_adapter = this.real_adapter[0];
	    var pvid_adapter = device.attributes.pvid_adapter.value;
	    this.virt_adapters.forEach(function (vea) {
		if (vea.name == pvid_adapter)
		    /**
		     * The virtual ethernet adapter pointed to by the
		     * `pvid_adapter` attribute.
		     * @type {Snapper~Ent}
		     */
		    this.pvid_adapter = vea;
	    }, this);
	    return this;
	}
	
	SEA.prototype = {
	    /**
	     * The horizontal spacing between LPARs
	     * @constant {Number}
	     * @default
	     */
	    hSpacing: 25,

	    /**
	     * The vertical spacing between LPARs.
	     * @constant {Number}
	     * @default
	     */
	    vSpacing: 50,

	    /**
	     * The padding around each CEC
	     * @constant {Number}
	     * @default
	     */
	    padding: 10,

	    /*
	     * This needs to draw the interconnects between the various
	     * pieces of the SEA.
	     */
	    createInterconnects: function createInterconnectsForSEA() {
		if (this.real_adapter.device.isEthChan()) {
		    this.real_adapter.createInterconnects();
		}

		var thisSelection = this.svg;
		var thisSVG = thisSelection[0];

		var realSVG = this.real_adapter.device.ent.svg[0];
		var realBBox = realSVG.getBBox();

		var selfSVG = this.ent.svg[0];
		var selfBBox = selfSVG.getBBox();

		var virtSVGs = this.virt_adapters.map(function (vea) {
		    return vea.device.ent.svg[0];
		}, this);
		var virtBBoxes = virtSVGs.map(function (svg) {
		    return svg.getBBox();
		}, this);
		var virt_delta = selfBBox.width / this.virt_adapters.length;

		var ctlSVG;
		var ctlBBox;

		var p1 = svgElement.createSVGPoint();
		var p2 = svgElement.createSVGPoint();
		var p3 = svgElement.createSVGPoint();

		/* Midway across the top of real box */
		p1.x = realBBox.width / 2;
		p1.y = 0;
		p1 = p1.matrixTransform(realSVG.getTransformToElement(thisSVG));

		/* Midway across the bottom of self box */
		p2.x = selfBBox.width / 2;
		p2.y = selfBBox.height;
		p2 = p2.matrixTransform(selfSVG.getTransformToElement(thisSVG));
		thisSelection.append(line(p1, p2));

		/* Do Virtuals */
		this.virt_adapters.forEach(function (vea, index) {
		    /* points accross top of self */
		    p1.x = virt_delta * ( index + 0.5 );
		    p1.y = 0;
		    p1 = p1.matrixTransform(selfSVG.getTransformToElement(thisSVG));
		    /* Middle of bottom of virt */
		    p2.x = virtBBoxes[index].width / 2;
		    p2.y = selfBBox.height;
		    p2 = p2.matrixTransform(virtSVGs[index].getTransformToElement(thisSVG));
		    thisSelection.append(line(p1, p2));
		}, this);

		/* Control channel is a polyline */
		if (this.ctl_chan) {
		    ctlSVG = this.ctl_chan.device.ent.svg[0];
		    ctlBBox = ctlSVG.getBBox();

		    /* start at middle of right side of self */
		    p1.x = selfBBox.width;
		    p1.y = selfBBox.height / 2;
		    p1 = p1.matrixTransform(selfSVG.getTransformToElement(thisSVG));

		    /* end at middle of bottom of control */
		    p3.x = ctlBBox.width / 2;
		    p3.y = ctlBBox.height;
		    p3 = p3.matrixTransform(ctlSVG.getTransformToElement(thisSVG));

		    /* corner is down from p3 and over from p1 */
		    p2.x = p3.x;
		    p2.y = p1.y;
		    thisSelection.append(polyline(p1, p2, p3));
		}
	    },

	    /**
	     * Draws the SEA by calling the draw routine for each of
	     * the adapters within the SEA, arranging them, and
	     * placing them into an SVG group element.  The `id` of
	     * the group element is the {@link Snapper~SEA#name name}
	     * of the SEA with `sea-` prepended.  e.g. sea-ent20.  The
	     * class of the group element is `sea`.
	     * @return {SVGTree}
	     */
	    draw: function drawForSEA() {
		var g = createElement('g').attr({
		    id: 'sea-' + this.id,
		    class: 'sea'
		});
		/* vea_* is for all VEAs including the control channel */
		var vea_x = 0, vea_y = this.padding, vea_height = 0, vea_shift = 0;
		/* virt_width is the width of the virtual adapters excluding the control channel */
		var virt_width;
		var virtuals = render(this.virt_adapters);
		var virtBBoxes = [];
		var selfEnt = this.ent.draw();
		var selfBBox = selfEnt[0].getBBox();
		var realEnt = this.real_adapter.draw();
		var realBBox = realEnt[0].getBBox();
		var ctlEnt, ctlBBox;
		var seaRect = createElement('rect').attr({
		    class: 'sea'
		});
		var maxWidth = 0;
		
		g.append(seaRect);
		virtuals.forEach(function (ent, index) {
		    var temp = ent[0].getBBox();
		    virtBBoxes.push(temp);
		    if (vea_height < temp.height)
			vea_height = temp.height;
		    vea_x += temp.width;
		}, this);
		vea_x += (virtuals.length - 1) * this.hSpacing;
		virt_width = vea_x;
		g.append(virtuals);

		if (this.ctl_chan) {
		    ctlEnt = this.ctl_chan.draw();
		    ctlBBox = ctlEnt[0].getBBox();
		    vea_x += ctlBBox.width + this.hSpacing;
		    g.append(ctlEnt);
		}
		g.append(selfEnt);
		g.append(realEnt);

		maxWidth = vea_x;
		if (maxWidth < realBBox.width)
		    maxWidth = realBBox.width;
		if (maxWidth < selfBBox.width)
		    maxWidth = selfBBox.width;
		maxWidth += (2 * this.padding);

		/*
		 * vea_x is the total width.  It will change to be the
		 * current x offset.  We figure this by figuring the offset
		 * of the first virtual adapter.
		 */
		vea_shift = (maxWidth - vea_x) / 2;
		vea_x = vea_shift;
		/* Now layout the virtuals + control channel */
		virtuals.forEach(function (ent, index) {
		    ent.attr({ transform: translate(vea_x, vea_y) });
		    vea_x += virtBBoxes[index].width + this.hSpacing;
		}, this);
		if (this.ctl_chan)
		    ctlEnt.attr({ transform: translate(vea_x, vea_y) });

		/* Move down to the SEA */
		vea_y += (vea_height + this.vSpacing);
		/* Place the SEA's ent */
		selfEnt.attr({ transform: translate(vea_shift + (virt_width - selfBBox.width) / 2, vea_y) });

		/* Move down to the real */
		vea_y += (selfBBox.height + this.vSpacing);
		/* Place the real ent */
		realEnt.attr({ transform: translate((maxWidth - realBBox.width) / 2, vea_y) });
		vea_y += (realBBox.height + this.padding);
		seaRect.attr({
		    width: maxWidth,
		    height: vea_y
		});

		/**
		 * A jQuery object for the SVG group that represents
		 * this SEA.
		 * @type {SVGTree}
		 */
		this.svg = g;
		this.svg.data('SEA', this);
		return g;
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.SEA = SEA;

	/**
	 * Represents an etherchannel.
	 * @constructor
	 * @param {Snapper~LPAR} lpar - the LPAR that contains this
	 * etherchannel.
	 * @param {Snapper~Device} device - the Device entry for this
	 * etherchannel.
	 */
	function EthChan(lpar, device) {
	    if (this === window) {
		return new EthChan(lpar, device);
	    }

	    /**
	     * The name taken from {@link Snapper~Device#name name} of
	     * the Device.
	     * @type {String}
	     */
	    this.name = device.name;

	    /**
	     * The LPAR that contains this etherchannel.
	     * @type {Snapper~LPAR}
	     */
	    this.lpar = lpar;

	    /**
	     * The Device entry for this etherchannel.
	     * @type {Snapper~Device}
	     */
	    this.device = device;
	    device.ethchan = this;

	    /**
	     * The ethernet adapter the etherchannel.
	     * @type {Snapper~Ent}
	     */
	    this.ent = new Ent(lpar, device);

	    /**
	     * The list of ethernet adapter making up the primary part
	     * of the etherchannel.
	     * @member {Array.<Snapper~Ent>} Snapper~EthChan#adapter_names
	     */
	    /**
	     * The backup ethernet adapter for this etherchannel (if
	     * any)
	     * @member {Snapper~Ent} Snapper~EthChan#backup_adapter
	     */
	    [ "adapter_names", "backup_adapter" ].forEach(function (attr) {
		var value = device.attributes[attr].value;

		
		this[attr] = value.split(',').map(function (devName) {
		    if (devName == "NONE") {
			return undefined;
		    }
		    var device = this.lpar.devices.byName[devName];
		    if (typeof device === 'undefined')
			alert("Ethchan ctor: device " + devName + " not found in parent LPAR " + lpar.name);
		    return new Ent(this.lpar, device);
		}, this);
	    }, this);
	    this.backup_adapter = this.backup_adapter[0];
	    return this;
	}

	EthChan.prototype = {
	    /**
	     * The horizontal spacing between LPARs
	     * @constant {Number}
	     * @default
	     */
	    hSpacing: 25,		// space between contained Ents

	    /**
	     * The vertical spacing between LPARs.
	     * @constant {Number}
	     * @default
	     */
	    vSpacing: 50,		// vertical spacing

	    /**
	     * The padding around each CEC
	     * @constant {Number}
	     * @default
	     */
	    padding: 10,

	    /*
	     * Currently, this does nothing since the interconnects are
	     * created at draw time.
	     */
	    createInterconnects: function createInterconnectsForEthChan() {
		return;
	    },

	    /**
	     * Draws the etherchannel by calling the draw routine for
	     * each of the adapters within the etherchannel, arranging
	     * them, and placing them into an SVG group element.  The
	     * `id` of the group element is the {@link
	     * Snapper~EthChan#name name} of the etherchannel with
	     * `ethchan-` prepended.  e.g. ethchan-ent20.  The class
	     * of the group element is `ethchan`.
	     * @return {SVGTree}
	     */
	    draw: function drawForEthChan() {
		/*
		 * An ether channel is the entN of the ether channel
		 * adapter itself, plus a list of primary ethernet
		 * adapters, plus an optional backup adapter.  These
		 * are then wrapped by an enclosing rectangle.
		 *
		 * The entN adapter is called selfEnt and its bounding
		 * box is called selfBBox.  The enclosing rectangle is
		 * called rect.
		 */
		var selfEnt = this.ent.draw();
		var selfBBox = selfEnt[0].getBBox();
		var primaries = render(this.adapter_names);
		var primBBoxes = [];
		var numPrimaries = primaries.length;
		var containerWidth = 0;
		var backup;
		var backupBBox;
		var x = this.padding, y = this.padding;
		var primHeight = 0;
		var g = createElement('g').attr({
		    id: 'ethchan-' + this.id,
		    class: 'ethchan'
		});
		var rect = createElement('rect').attr({
		    class: 'ethchan'
		});

		g.append(rect);
		primaries.forEach(function (ent) {
		    var temp = ent[0].getBBox();
		    primBBoxes.push(temp);
		    containerWidth += temp.width;
		});
		if (this.backup_adapter)
		    backup = this.backup_adapter.draw();

		containerWidth += (numPrimaries - 1) * this.hSpacing;
		selfBBox.x = this.padding + ((containerWidth - selfBBox.width) / 2);
		selfBBox.y = y;
		y += selfBBox.height + this.vSpacing;
		g.append(selfEnt);
		if (backup) {
		    var temp;

		    backupBBox = backup[0].getBBox();
		    temp = this.hSpacing + backupBBox.width;
		    containerWidth += temp;
		    backup.attr({ transform: translate(x, y) });
		    backupBBox.x = x;
		    backupBBox.y = y;
		    selfBBox.x += temp;
		    x += temp;
		    if (primHeight < backupBBox.height)
			primHeight = backupBBox.height;
		}
		selfEnt.attr({ transform: translate(selfBBox.x, selfBBox.y) });
		primaries.forEach(function (ent, index) {
		    var bbox = primBBoxes[index];
		    ent.attr({ transform: translate(x, y) });
		    bbox.x = x;
		    bbox.y = y;
		    x += (bbox.width + this.hSpacing);
		    if (primHeight < bbox.height)
			primHeight = bbox.height;
		}, this);
		g.append(primaries);
		if (backup)
		    g.append(backup);
		x += this.padding - this.hSpacing;
		y += this.padding + primHeight;
		rect.attr({
		    width: x,
		    height: y
		});

		/* Hookup paths to primaries */
		var parent_y = selfBBox.y + selfBBox.height;
		var parent_inc = selfBBox.width / primaries.length;
		var parent_x = selfBBox.x + (parent_inc / 2);

		primaries.forEach(function (ent, index) {
		    var bbox = primBBoxes[index];
		    var prim_x = bbox.x + bbox.width / 2;
		    var prim_y = bbox.y;
		    var line = createElement('line').attr({
			x1: parent_x,
			y1: parent_y,
			x2: prim_x,
			y2: prim_y
		    });
		    parent_x += parent_inc;
		    g.append(line);
		}, this);

		/* backup is a polyline */
		if (backup) {
		    var p1 = svgElement.createSVGPoint();
		    var p2 = svgElement.createSVGPoint();
		    var p3 = svgElement.createSVGPoint();

		    p1.x = selfBBox.x;
		    p1.y = selfBBox.y + (selfBBox.height / 2);
		    p3.x = backupBBox.x + (backupBBox.width / 2);
		    p3.y = backupBBox.y;
		    p2.x = p3.x;
		    p2.y = p1.y;

		    g.append(polyline(p1, p2, p3));
		}

		/**
		 * A jQuery object for the SVG group that represents
		 * this etherchannel.
		 * @type {SVGTree}
		 */
		this.svg = g;
		this.svg.data('EthChan', this);
		return g;
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.EthChan = EthChan;

	/**
	 * Creates an ethernet adapter
	 * @constructor
	 * @param {LPAR} lpar - The LPAR for which this Ent will belong.
	 * @param {Device} device - The Device entry for this Ent.
	 */
	function Ent(lpar, device) {
	    if (this === window) {
		return new Ent(lpar, device);
	    }

	    var temp;

	    /**
	     * The LPAR that contains this ethernet adapter.
	     * @type {Snapper~LPAR}
	     */
	    this.lpar = lpar;

	    /**
	     * The Device entry for this etherchannel.
	     * @type {Snapper~Device}
	     */
	    this.device = device;
	    device.ent = this;

	    /**
	     * The id of the adapter which is the lpar name plus the
	     * adapter name.
	     * @tyep {String}
	     */
	    this.id = lpar.name + '-' + device.name;

	    /**
	     * The name taken from {@link Snapper~Device#name name} of
	     * the Device.
	     * @type {String}
	     */
	    this.name = device.name;

	    // find our entstat output... if any
	    /**
	     * The entry from netstat -v found usually in
	     * tcpip/tcpip.snap for this ethernet adapter.
	     * @type {(String|Array.<Object>)}
	     */
	    this.entstat = undefined;

	    /**
	     * Points to the virtual switch that this Ent is
	     * connected to if the Ent is a VEA.
	     * @type {Snapper~VirtualSwitch}
	     */
	    this.virtual_switch = undefined;

	    /*
	     * This dance probably should be inside of lpar rather
	     * than exposed.
	     */
	    temp = lpar.snap.db;
	    if (temp) temp = temp.netstat_v;
	    if (temp) this.entstat = temp[this.name];
	    if (this.entstat && device.isVEA()) {
		this.virtual_switch = lpar.cec.getVirtualSwitch(this.entstat.switch_id, this);
	    }

	    return this;
	}

	Ent.prototype = {
	    /**
	     * The ethernet adapter is represented by a rectangle.
	     * This value provides the width of the rectangle.
	     * @constant {Number}
	     * @default
	     */
	    width: 50,

	    /**
	     * The ethernet adapter is represented by a rectangle.
	     * This value provides the height of the rectangle.
	     * @constant {Number}
	     * @default
	     */
	    height: 50,

	    /**
	     * Null routine to provide API.
	     */
	    createInterconnects: function createInterconnectsForEnt() {
		return;
	    },

	    /**
	     * Draws a square to represent the ethernet adapter and
	     * places a text string with the name inside of it
	     * wrapping both in an SVG group element with the `id` set
	     * to the {@link Snapper~Ent#name name} of the adapter and
	     * `class` set to `ent`.
	     * @return {SVGTree}
	     */
	    draw: function drawForEnt() {
		var g = createNamedRect(this.name, {
		    id: this.id,
		    class: 'ent',
		    width: this.width,
		    height: this.height
		});

		g.commandList();
		// g.foo = g.commandList("instance");
		// g.foo.addCommand("bob");

		if (this.entstat) {
		    g.commandList("instance").addCommand("entstat", this.entstat);
		    g.commandList("instance").addCommand("purple", "purple");
		}

		/**
		 * A jQuery object for the SVG group that represents
		 * this ethernet adapter.
		 * @type {SVGTree}
		 */
		this.svg = g;
		this.svg.data('Ent', this);
		return g;
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.Ent = Ent;

	/**
	 * Represents a virtual switch within a CEC.
	 * @constructor
	 * @param {CEC} cec - The CEC that the virtual switch belongs to.
	 * @param {String} id - The id for the virtual switch
	 */
	function VirtualSwitch(cec, id) {
	    if (this === window) {
		return new VirtualSwitch(cec, id);
	    }

	    /**
	     * Reference to the CEC that this LPAR is a part of.
	     * @type {CEC}
	     */
	    this.cec = cec;
	    
	    /**
	     * The id of the virtual switch which is the id of the CEC
	     * with the id of the switch.
	     * @type {String}
	     */
	    this.id = cec.id + '-' + id;
	    
	    /**
	     * The name for this virtual switch is equal to its id.
	     * @type {String}
	     */
	    this.name = id;
	    
	    /**
	     * An array of connections to VEAs to this switch.
	     * @type {Array.<Snapper~Ent>}
	     */
	    this.connections = [];

	    return this;
	}

	VirtualSwitch.prototype = {
	    /**
	     * The ethernet adapter is represented by a rectangle.
	     * This value provides the width of the rectangle.
	     * @constant {Number}
	     * @default
	     */
	    width: 150,

	    /**
	     * The ethernet adapter is represented by a rectangle.
	     * This value provides the height of the rectangle.
	     * @constant {Number}
	     * @default
	     */
	    height: 50,

	    /**
	     * Currently does nothing.  There are no elements within a
	     * virtual switch so I don't see how there will be any
	     * interconnects needed between those elements.
	     */
	    createInterconnects: function createInterconnectsForVirtualSwitch() {
	    },

	    /**
	     * Creates an SVG group node, add in a rectangle with its name embedded within
	     */
	    draw: function drawForVirtualSwitch() {
		var g = createNamedRect(this.name, {
		    id: this.id,
		    class: 'virtual-switch',
		    width: this.width,
		    height: this.height
		});

		g.commandList({ });
		// g.foo = g.commandList("instance");
		// this.commandList = new CommandList(g);

		/**
		 * A jQuery object for the SVG group that represents
		 * this ethernet adapter.
		 * @type {SVGTree}
		 */
		this.svg = g;
		this.svg.data('VirtualSwitch', this);
		return g;
	    },

	    /**
	     * Adds a connection from the specified {@link Snapper~Ent
	     * Ent} to this virtual switch.
	     */
	    addConnection: function virtualSwitchAddConnection(ent) {
		this.connections.push(ent);
	    }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.VirtualSwitch = VirtualSwitch;

	/**
	 * A class for attributes used by Device.  It is possible to
	 * have 0, 1, or several CuAt entries as well as 0, 1, or more
	 * PdAt entries but it should never have zero entries for both
	 * arrays.
	 *
	 * This class mimics the Attribute Ruby class providing
	 * various convenience methods.
	 *
	 * @constructor
	 * @param {Array.<CuAt>} cu_ats - An array of CuAt entries as
	 * parsed by the ODM Ruby parser.
	 * @param {Array.<PdAt>} pd_ats - An array of CuAt entries as
	 * parsed by the ODM Ruby parser.
	 */
	function Attribute(cu_ats, pd_ats) {
	    if (this === window) {
		return new VirtualSwitch(cu_ats, pd_ats);
	    }

	    if (!cu_ats || cu_ats.length === undefined)
		throw new TypeError("cu_ats is not an array");
	    if (!pd_ats || pd_ats.length === undefined)
		throw new TypeError("pd_ats is not an array");
	    if (cu_ats.length == 0 && pd_ats.length == 0)
		throw new TypeError("Both cu_ats and pd_ats can not be empty");

	    /**
	     * The array of CuAt entries passed into the constructor.
	     * @type {Array.<CuAt>}
	     */
	    this.cu_ats = cu_ats;

	    /**
	     * The array of PdAt entries passed into the constructor.
	     * @type {Array.<PdAt>}
	     */
	    this.pd_ats = pd_ats;
	    return this;
	}

	Attribute.prototype = {
	    /**
	     * Returns the first CuAt entry or null if none were
	     * passed in.
	     * @return {CuAt}
	     */
	    get cu_at () { return this.cu_ats[0]; },

	    /**
	     * Returns the first PdAt entry or null if none were
	     * passed in.
	     * @return {PdAt}
	     */
	    get pd_at () { return this.pd_ats[0]; },

	    /**
	     * Returns the value attribute of all of the CuAt entries.
	     * @return {Array.<Integer|String>}
	     */
	    get values () {
		return this.cu_ats.map(function (cu_at, index, collection) {
		    return cu_at.value;
		});
	    },

	    /**
	     * Returns true if the attribute has been customized.  In
	     * particular, if there are any CuAt entries and if at
	     * least one of them is not equal to the deflt value of
	     * the PdAt.  If only CuAt entries exist and no PdAt
	     * entry, then it is assumed that the attribute has been
	     * customized.
	     * @return {Boolean}
	     */
	    get customized () {
		var deflt = this.deflt;
		if (this.cu_ats.length == 0)
		    return false;
		return !this.values.every(function(value, index, collection) {
		    return (value == deflt);
		});
	    },

	    /**
	     * Returns the name of the firust CuAt which is the
	     * logical device name that the attribute belongs to.
	     * @return {String|null}
	     */
	    get name () { 
		return this.cu_ats.length == 0 ? null : this.cu_ats[0].name;
	    },

	    /**
	     * Returns the value of the attribute.  If there is at
	     * least one CuAt, then it returns the value of the first
	     * CuAt entry.  Otherwise it will return the deflt value
	     * of the PdAt entry.  (Note that one or the other must
	     * exist).
	     * @return {Integer|String}
	     */
	    get value () { 
		return this.cu_ats.length == 0 ? this.deflt : this.cu_ats[0].value;
	    },

	    /**
	     * Returns the uniquetype of the PdAt if present or null.
	     * @return {String|null}
	     */
	    get uniquetype () {
		return this.pd_ats.length == 0 ? null : this.pd_ats[0].uniquetype;
	    },

	    /**
	     * Returns the deflt of the PdAt if present or null.
	     * @return {String|null}
	     */
	    get deflt () {
		return this.pd_ats.length == 0 ? null : this.pd_ats[0].deflt;
	    },

	    /**
	     * Returns the width of the PdAt if present or null.
	     * @return {String|null}
	     */
	    get width () {
		return this.pd_ats.length == 0 ? null : this.pd_ats[0].width;
	    },

	    /**
	     * Returns the values of the PdAt if present or null.
	     * @return {String|null}
	     */
	    get pd_at_values () {
		return this.pd_ats.length == 0 ? null : this.pd_ats[0].values;
	    },

	    /**
	     * Intended to be a private function.  Returns either the
	     * first PdAt entry or the first CuAt entry.
	     * @return {PdAt|CuAt}
	     */
	    get either () {
		return this.pd_ats.length == 0 ? this.cu_ats[0] : this.pd_ats[0];
	    },

	    /**
	     * Returns the name of the attribute
	     * @return {String}
	     */
	    get attribute () { return this.either.attribute; },

	    /**
	     * Returns the name of the generic
	     * @return {String}
	     */
	    get generic () { return this.either.generic; },

	    /**
	     * Returns the name of the nls_index
	     * @return {String}
	     */
	    get nls_index () { return this.either.nls_index; },

	    /**
	     * Returns the name of the rep
	     * @return {String}
	     */
	    get rep () { return this.either.rep; },

	    /**
	     * Returns the name of the type
	     * @return {String}
	     */
	    get type () { return this.either.type; }
	};

	if (typeof window.snapper === "undefined") window.snapper = {};
	window.snapper.Attribute = Attribute;

	/*
	 * window.snapper is created by a script tag that page.rb produces.
	 */
	window.snapper.world = new World();
    }
)(window, document);
