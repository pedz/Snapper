/**
 * @external jQuery
 * @see http://api.jquery.com/Types/#jQuery
 * @desc A jQuery object as returned from jQuery()
 * @typedef jQuery
 */
/**
 * @external SVGElement
 * @see http://www.w3.org/TR/SVG/struct.html#SVGElement
 * @desc An SVG element as specified by SVG.
 * @typedef SVGElement
 */
/**
 * @external LineElement
 * @see http://www.w3.org/TR/SVG/shapes.html#LineElement
 * @desc A Line element as specified by SVG.
 * @typedef LineElement
 */
/**
 * @external PolylineElement
 * @see http://www.w3.org/TR/SVG/shapes.html#PolylineElement
 * @desc A Polyline element as specified by SVG.
 * @typedef PolylineElement
 */
/**
 * @external SVGPoint
 * @see http://www.w3.org/TR/SVG/coords.html#InterfaceSVGPoint
 * @desc The Point interface as specified by SVG
 * @typedef SVGPoint
 */
/**
 * @desc Output from the Ruby snapper in the form of an Object.  A
 * snap as well as a perfpmr can only be for one LPAR thus it is for a
 * single CEC as well.
 * @typedef {Object} SnapData
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
     * @alias Snapper
     * @constructor
     * @param {DOMWindow} window - The global window
     * @param {DOMDocument} document - The global document
     * @param {undefined} undefined - Javascript undefined
     */
    function Snapper(window, document, undefined) {
	"use strict";

	/**
	 * Currently unused global to the Environment that specifies the SVG namespace
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
	    newElement = document.createElementNS(svgElement.namespaceURI, tagName);
	    newElement.oldGetBBox = newElement.getBBox;
	    newElement.getBBox = function() {
		var rect;

		try {
		    rect = this.oldGetBBox();
		}
		catch (err) {
		    svgSelection.append(this);
		    rect = this.oldGetBBox();
		    $(this).detach();
		}
		return rect;
	    };
	    return $(newElement);
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
	 * @constructor
	 */
	function World() {
	    if (this === window) {
		return new World();
	    }

	    /**
	     * The name of the world which is always "World"
	     * @type {String}
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
	     * @type {Array.<SnapData>}
	     */
	    this.snaps = [];
	    return this;
	}

	World.prototype = {
	    /**
	     * The border in pixels to put around the world when it is
	     * drawn.
	     * @constant {Number}
	     * @default
	     */
	    borderWidth: 5,

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
		var x = this.borderWidth, y = this.borderWidth;
		var g = createElement('g').attr({
		    id: this.name,
		    class: 'world'
		});
		render(this.cecs).forEach(function transformAndAppendCEC(cec) {
		    g.append(cec.attr({ transform: translate(x, y) }));
		    x += 20;
		});

		/**
		 * The SVG tree for the World
		 * @type {SVGTree}
		 */
		this.svg = g;
		$('svg').append(g);
	    },

	    /**
	     * Adds a snap to the list of snaps and causes the values
	     * of the snap to be merged into the world.  The
	     * 'id_to_system' of the 'sys0' elemeent of the 'CuAt'
	     * element in the data
	     * (e.g. data['CuAt']['sys0']['id_to_system'] ) is used to
	     * determine the name of the CEC.  A {@link Snapper~CEC
	     * CEC} is created and its {@link Snapper~CEC#addData
	     * addData} method is called with the same data passed
	     * into this function.
	     *
	     * @param {SnapData} data - Output from the snapper Ruby
	     * code in the form.
	     */
	    addSnap: function addSnapToWorld(data) {
		/* Mostly for debugging purposes */
		this.snaps.push(data);

		var cuats = data['CuAt'];
		if (typeof cuats === 'undefined') {
		    alert("World.addSnap: CuAt not found in snap data");
		    return;
		}

		var sys0_attrs = cuats.filter(function (cuat) { return cuat['name'] == 'sys0'; });
		if (sys0_attrs.length === 0) {
		    alert("World.addSnap: no sys0 attributes found");
		    return;
		}

		var system_id_attrs = sys0_attrs.filter(function (cuat) {
		    return cuat['attribute'] == "id_to_system";
		});
		if (system_id_attrs.length != 1) {
		    if (system_id_attrs.length == 0)
			alert("World.addSnap: id_to_system CuAt entry not found");
		    else
			alert("World.addSnap: multiple id_to_system CuAt entries found");
		    return;
		}

		var system_id = system_id_attrs[0]['value'];
		if (typeof system_id === 'undefined' || system_id == "") {
		    alert("World.addSnap: id_to_system is either undefined or the empty string");
		    return;
		}

		if (typeof this.cecs[system_id] === 'undefined')
		    this.cecs[system_id] = new CEC(this, system_id);
		this.cecs[system_id].addData(data);
	    }
	};

	/**
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
	     * The values passed to the {@link Snapper~CEC#addData
	     * addData} method.
	     * @type {Array.<SnapData>}
	     */
	    this.data = [];

	    /**
	     * The array of {@link Snapper~LPAR LPARs} within this
	     * CEC.
	     * @type {Array.<Snapper~LPAR>}
	     */
	    this.lpars = {};
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
	    vSpacing: 50,

	    /**
	     * The border around each CEC
	     * @constant {Number}
	     * @default
	     */
	    borderWidth: 10,

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
	    },

	    /**
	     * draws the CEC by calling {@link Snapper~render render}
	     * with {@link Snapper~CEC#lpars lpars} and placing them
	     * into a group element with an `id` of the CEC's {@link
	     * Snapper~CEC#name name} and a `class` of `cec`.
	     * @return {SVGTree}
	     */
	    draw: function drawForCEC() {
		var x = this.borderWidth, y = this.borderWidth, max_height = 0;
		var g = createElement('g').attr({
		    id: this.name,
		    class: 'cec'
		});
		var rect = createElement('rect').attr({
		    class: 'cecRect'
		});

		g.append(rect);
		render(this.lpars).forEach(function (lpar) {
		    var bbox = lpar[0].getBBox();

		    g.append(lpar.attr({ transform: translate(x, y) }));
		    x += bbox.width + this.hSpacing;
		    if (max_height < bbox.height)
			max_height = bbox.height;
		}, this);
		max_height += (2 * this.borderWidth);
		x += (this.borderWidth - this.hSpacing);
		rect.attr({
		    width: x,
		    height: max_height
		});
		svgSelection.attr({ width: x + this.hSpacing, height: max_height + this.vSpacing });

		/**
		 * The SVG tree for this CEC.
		 * @type {SVGTree}
		 */
		this.svg = g;
		return g;
	    },

	    /**
	     * @param {SnapData} data - The data from the snap for this
	     * CEC.
	     */
	    addData: function (data) {
		/* Again... mostly for debugging purposes */
		this.data.push(data);

		var cuats = data['CuAt'];
		if (typeof cuats === 'undefined') {
		    alert("CEC.addData: CuAt not found in snap data");
		    return;
		}

		var sys0_attrs = cuats.filter(function (cuat) { return cuat['name'] == 'sys0'; });
		if (sys0_attrs.length === 0) {
		    alert("CEC.addData: no sys0 attributes found");
		    return;
		}

		var partition_id_attrs = sys0_attrs.filter(function (cuat) {
		    return cuat['attribute'] == "id_to_partition";
		});
		if (partition_id_attrs.length != 1) {
		    if (partition_id_attrs.length == 0)
			alert("CEC.addData: id_to_partition CuAt entry not found");
		    else
			alert("CEC.addData: multiple id_to_partition CuAt entries found");
		    return;
		}

		var partition_id = partition_id_attrs[0]['value'];
		if (typeof partition_id === 'undefined' || partition_id == "") {
		    alert("CEC.addData: id_to_partition is either undefined or the empty string");
		    return;
		}

		if (typeof this.lpars[partition_id] === 'undefined')
		    this.lpars[partition_id] = new LPAR(this, partition_id, data);
		else
		    alert("CEC.addData: attempt to redefine partition " + partition_id + " within CEC " + this.id);
	    }
	};

	/**
	 * Represents an LPAR
	 * @constructor
	 * @param {CEC} cec - The CEC that the LPAR belongs to.
	 * @param {PartitionId} id - The partition id for this LPAR
	 * @param {SnapData} data - The snap data for this LPAR
	 */
	function LPAR(cec, id, data) {
	    if (this === window) {
		return new LPAR(cec, id);
	    }

	    /**
	     * Reference to the CEC that this LPAR is a part of.
	     * @type {CEC}
	     */
	    this.cec = cec;

	    /**
	     * The partition id for this LPAR
	     * @type {PartitionId}
	     */
	    this.id = id;

	    /**
	     * The data from the snap taken on this LPAR
	     * @type {SnapData}
	     */
	    this.data = data;

	    /**
	     * Each Object is a stanza from the CuAt odm database.
	     * @type {Array.<Object>}
	     */
	    this.cuat = data['CuAt'];

	    /**
	     * Each Object is a stanza from the CuDv odm database.
	     * @type {Array.<Object>}
	     */
	    this.cudv = data['CuDv'];

	    /**
	     * Each Object is a stanza from the PdAt odm database.
	     * Remember that some snaps do not have PdAt so this may
	     * be undefined.
	     * @type {Array.<Object>}
	     */
	    this.pdat = data['PdAt'];

	    /**
	     * Each Object is a stanza from the PdDv odm database.
	     * Remember, this may be undefined since some snaps do not
	     * have the predefined entries of the ODM database.
	     * @type {Array.<Object>}
	     */
	    this.pddv = data['PdDv'];

	    /**
	     * An object with two elements: <dl>
	     * <dt>`byName`</dt><dd>{@link Snapper~Device Devices}
	     * indexed by their logical name</dd>
	     * <dt>`byType`</dt><dd>{@link Snapper~Device Devices}
	     * indexed by the PdDvLn attribute which is also called
	     * uniquetype in other ODM tables sucha s CuAt and
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
	    data['CuDv'].forEach(function (cudv) {
		var newDevice = new Device(this.lpar, cudv, this.data);
		var thisType = this.devices.byType[cudv['PdDvLn']];

		this.devices.byName[cudv['name']] = newDevice;
		if (typeof thisType === 'undefined')
		    thisType = (this.devices.byType[cudv['PdDvLn']] = []);
		thisType.push(newDevice);
	    }, this);

	    /**
	     * The hostname of the LPAR comes from the `hostname`
	     * attribute of the `inet0` stanza.
	     * @type {String}
	     */
	    this.hostname = this.devices.byName['inet0'].attributes['hostname'].values[0]['value'];

	    /**
	     * The name of the LPAR is set equal to the hostname.
	     * @type {String}
	     */
	    this.name = this.hostname;

	    if (this.devices.byType['adapter/pseudo/sea']) {
		/**
		 * An array of SEAs (if any) present in this LPAR.
		 * @type {Array.<Snapper~SEA>}
		 */
		this.seas = this.devices.byType['adapter/pseudo/sea'].map(function (device) {
		    return new SEA(this, device);
		}, this);
	    }

	    /**
	     * The interfaces within the LPAR.  we find all of the
	     * if/EN/en (which ignores token ring and all other types
	     * of interfaces) which have a customized netaddr.
	     * @type {Array.<Snapper~Ifnet>}
	     */
	    this.ifnets = this.devices.byType['if/EN/en'].filter(function (device) {
		return device.attributes['netaddr'].values.length > 0;
	    }).map(function (device) {
		return new Ifnet(this, device);
	    }, this);

	    /**
	     * We run through interfaces and filter out the SEAs and are
	     * left with non-SEA adapters with an interface.
	     * @type {Array.<Snapper~Ent>}
	     */
	    this.adapters = this.ifnets.filter(function (ifnet) {
		return !(ifnet.adapter.isSEA());
	    }).map(function (ifnet) {
		var ent = new Ent(this, ifnet.adapter);
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
	     * The border around each CEC
	     * @constant {Number}
	     * @default
	     */
	    borderWidth: 10,

	    /**
	     * Calls {@link Snapper~SEA#createInterconnects
	     * createInterconnects} for each SEA and then creates the
	     * interconnects from the interfaces to their adapter.
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

			// p1.x = 0 - (2 * SEA.prototype.borderWidth);
			// p1.y = adapterBBox.height - (2 * SEA.prototype.borderWidth);
			
			p1 = p1.matrixTransform(adapterSVG[0].getTransformToElement(lparSVG));
			p1.x -= ((2 * SEA.prototype.borderWidth) + (ifnetBBox.width));
			p1.y += (adapterBBox.height / 2) - (2 * SEA.prototype.borderWidth) - ifnetBBox.height;
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
	     * Snapper~LPAR#adapters} and also renders the interfaces
	     * for those adapters.  All of these are put into a group
	     * element with an `id` of the LPAR's {@link
	     * Snapper~LPAR#name name} and a `class` of `lpar`.
	     * @return {SVGTree}
	     */
	    draw: function drawForLPAR() {
		var x = this.borderWidth, y = this.borderWidth;
		var g = createElement('g').attr({
		    id: this.name,
		    class: 'lpar'
		});
		var height = 0;
		var rect = createElement('rect').attr({
		    class: 'lparRect'
		});
		g.append(rect);

		// render the SEAs and the associated interface if any
		if (this.seas) {
		    this.rendered_seas = render(this.seas).forEach(function (seaSVG, index) {
			var sea = this.seas[index];
			var seaBBox = seaSVG[0].getBBox();
			var ifnetBBox;
			
			// Interfaces go on the left
			this.ifnets.forEach(function (ifnet) {
			    if (ifnet.adapter === sea.device) {
				sea.rendered_ifnet = ifnet.draw();
				ifnetBBox = sea.rendered_ifnet[0].getBBox();
				// Can't place it until the createInterconnects phase
				g.append(sea.rendered_ifnet);
				x += ifnetBBox.width + SEA.prototype.borderWidth;
			    }
			}, this);
			g.append(seaSVG.attr({ transform: translate(x, y) }));
			if (height < seaBBox.height)
			    height = seaBBox.height;
			x += seaBBox.width + this.hSpacing;
			// Check for interface
		    }, this);
		}

		// render the non-SEA adapters and their interfaces
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
		    temp_height = ifnetBBox.height + (2 * SEA.prototype.borderWidth);
		    if (half_adapter_height > temp_height)
			temp_height = adapterBBox.height;
		    else
			temp_height += half_adapter_height;
		    if (height < temp_height)
			height = temp_height;

		    ifnet_x = x;
		    ifnet_y = y + height - half_adapter_height - ifnetBBox.height - (SEA.prototype.borderWidth * 2);
		    g.append(adapter.rendered_ifnet.attr({ transform: translate(ifnet_x, ifnet_y) }));
		    x += ifnetBBox.width + (SEA.prototype.borderWidth * 2);
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

		height += (2 * this.borderWidth);
		x += (this.borderWidth - this.hSpacing);
		rect.attr({
		    width: x,
		    height: height
		});

		/**
		 * The SVG tree for this LPAR
		 * @type {SVGTree}
		 */
		this.svg = g;
		return g;
	    }
	};
	
	/**
	 * The Ifnet class represents the interfaces such as en0.
	 * @constructor
	 * @param {Snapper~LPAR} lpar - The LPAR the interface belongs to.
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
	     * The name such as en0 or en5.
	     * @type {String}
	     */
	    this.name = device.name;

	    /**
	     * The Device entry for this interface.
	     * @type {Snapper~Device}
	     */
	    this.device = device;

	    device.ifnet = this;

	    /**
	     * The adapter that the interface is sitting on top of.
	     * @type {Snapper~Device}
	     */
	    this.adapter = lpar.devices.byName[device.name.replace(/e[nt]/, 'ent')];
	    return this;
	}

	Ifnet.prototype = {
	    /**
	     * The interface is represented by an equilateral
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
	     * Draws the interface with the name of the interface
	     * embeded and places those items into an SVG group
	     * element with an `id` of the interface's {@link
	     * Snapper~Ifnet#name name} and a `class` of `ifnet`.
	     * @return {SVGTree}
	     */
	    draw: function drawForIfnet() {
		var mid = this.side / 2;
		var height = Math.sqrt((mid * mid) + (this.side * this.side));
		var g = createElement('g').attr({
		    id: this.name,
		    class: 'ifnet'
		}).append(polyline({ x: 0, y: 0 }, { x: this.side, y: 0 }, { x: mid, y: height }).attr({
		    class: 'ifnet'
		})).append(createElement('text').attr({
		    x: this.side / 2,
		    y: this.side / 2
		}).append(this.name));
		
		/**
		 * A jQuery object for the SVG group that represents
		 * this interface
		 * @type {SVGTree}
		 */
		this.svg = g;
		return g;
	    }
	};

	/**
	 * A Device is a common place gathers common attributes and
	 * methods together.
	 *
	 * As other objects are created using this device, they hook
	 * themselves in using an obvious name.  e.g. when an Ent is
	 * created, it hooks in as device.ent.  When a SEA is created,
	 * it hooks in as device.sea.  A direct svg element is not
	 * saved because it is ambiguous.
	 * @constructor
	 * @param {Snapper~LPAR} lpar - The LPAR that this Device will
	 * be a part of.
	 * @param {Object} cudv - The CuDv entry for this device.
	 * @param {SnapData} data - The snap data.
	 */
	function Device(lpar, cudv, data) {
	    if (this === window) {
		return new Device(lpar, cudv, data);
	    }

	    var uniquetype = cudv['PdDvLn'];
	    var name = cudv['name'];

	    /**
	     * The LPAR that this device is a part of.
	     * @type {Snapper~LPAR}
	     */
	    this.lpar = lpar;

	    /**
	     * The CuDv entry for this device.
	     * @type {Object}
	     */
	    this.cudv = cudv;

	    /**
	     * The rest of the data from the LPAR.  This probably
	     * should not be saved here.
	     */
	    this.data = data;

	    /**
	     * The `name` field taken from the {@link
	     * Snapper~Device#cudv CuDv} entry.
	     * @type {String}
	     */
	    this.name = name;

	    /**
	     * The `uniquetype` field taken from the {@link
	     * Snapper~Device#cudv CuDv} entry.
	     * @type {String}
	     */
	    this.uniquetype = uniquetype;

	    /**
	     * The corresponding PdDv (predefined Device) entry for
	     * this device.  Note that this may be null in the case
	     * that the predefined ODM files were not gathered.
	     * @type {Object}
	     */
	    this.pddv = data['PdDv'].filter(function (pddv) { return pddv['uniquetype'] == uniquetype; })[0];

	    /**
	     * The array of PdAt (predefined attributes) for this
	     * device entry.  Note that this may be null in the case
	     * that the predefined ODM files were not gathered.
	     * @type {Array.<Object>}
	     */
	    this.pdat = data['PdAt'].filter(function (pdat) { return pdat['uniquetype'] == uniquetype; });

	    /**
	     * The array of CuAt (customized attributes) for this
	     * device entry.
	     * @type {Array.<Object>}
	     */
	    this.cuat = data['CuAt'].filter(function (cuat) { return cuat['name'] == name; });

	    /**
	     * The attributes stored by the attribute name for this
	     * device. Each element is an Object with two
	     * attributes:<dl>
	     * <dt>`pdat`</dt><dd>The PdAt entry for this
	     * attribute.<dd>
	     * <dt>`values`</dt><dd>An array of CuAt entries (very
	     * often only one) for this attribute (for this
	     * device)</dd>
	     * </dl>
	     */
	    this.attributes = {};
	    /* Set up an attribute for each PdAt entry -- should be only one PdAt entry per attribute */
	    this.pdat.forEach(function (pdat) {
		this.attributes[pdat['attribute']] = {
		    pdat: pdat,
		    values: []
		};
	    }, this);
	    /* Now fill in values array from customized attributes */
	    this.cuat.forEach(function (cuat) {
		var attribute = this.attributes[cuat['attribute']];
		if (typeof attribute === 'undefined') // rare but it does happen
		    attribute = (this.attributes[cuat['attribute']] = { values: [] });
		attribute.values.push(cuat);
	    }, this);

	    /**
	     * @type {Snapper~Ifnet}
	     */
	    this.ifnet = nil;

	    /**
	     * @type {Snapper~SEA}
	     */
	    this.sea = nil;

	    /**
	     * @type {Snapper~EthChan}
	     */
	    this.ethchan = nil;
	    return this;
	}

	Device.prototype = {
	    /** Returns true if the device is a SEA */
	    isSEA: function () {
		return this.pddv['DvDr'] === "seadd";
	    },

	    /** Returns true if the device is an etherchannel */
	    isEthChan: function () {
		return this.pddv['DvDr'] === "ethchandd";
	    },

	    /** Returns true if the device is a virtual ethernet
	     * adapter */
	    isVEA: function () {
		return this.pddv['DvDr'] === "vioentdd";
	    },

	    /** Returns true if the device is an ethernet adapter */
	    isEnt: function () {
		return this.pddv['prefix'] === "ent";
	    }
	};

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
		var values = device.attributes[attr].values;

		if (values.length == 0)
		    this[attr] = [];
		else
		    this[attr] = values[0]['value'].split(',').map(function (devName) {
			var device = this.lpar.devices.byName[devName];
			if (typeof device === 'undefined')
			    alert("SEA ctor: device " + devName + " not found in parent LPAR " + lpar.name);
			if (device.isEthChan())
			    return new EthChan(this.lpar, device);
			else
			    return new Ent(this.lpar, device);
		    }, this);
	    }, this);

	    this.ctl_chan = this.ctl_chan[0];
	    this.real_adapter = this.real_adapter[0];
	    var pvid_adapter = device.attributes['pvid_adapter'].values[0]['value'];
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
	     * The border around each CEC
	     * @constant {Number}
	     * @default
	     */
	    borderWidth: 10,

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

		var realSVG = this.real_adapter.device.ent.svg[0]
		var realBBox = realSVG.getBBox();

		var selfSVG = this.ent.svg[0]
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
		    id: 'sea-' + this.name,
		    class: 'sea'
		});
		/* vea_* is for all VEAs including the control channel */
		var vea_x = 0, vea_y = this.borderWidth, vea_height = 0, vea_shift = 0;
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
		    class: 'seaRect'
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
		maxWidth += (2 * this.borderWidth);

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
		vea_y += (realBBox.height + this.borderWidth);
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
		return g;
	    }
	};
	
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
	    this.ent = new Ent(lpar, device);
	    [ "adapter_names", "backup_adapter" ].forEach(function (attr) {
		var values = device.attributes[attr].values;

		if (values.length == 0)
		    this[attr] = [];
		else
		    this[attr] = values[0]['value'].split(',').map(function (devName) {
			var device = this.lpar.devices.byName[devName];
			if (typeof device === 'undefined')
			    alert("SEA ctor: device " + devName + " not found in parent LPAR " + lpar.name);
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
	     * The border around each CEC
	     * @constant {Number}
	     * @default
	     */
	    borderWidth: 10,

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
		var selfEnt = this.ent.draw();
		var selfBBox = selfEnt[0].getBBox();
		var primaries = render(this.adapter_names);
		var primBBoxes = [];
		var numPrimaries = primaries.length;
		var contWidth = 0;
		var backup;
		var backupBBox;
		var x = this.borderWidth, y = this.borderWidth;
		var primHeight = 0;
		var g = createElement('g').attr({
		    id: 'ethchan-' + this.name,
		    class: 'ethchan'
		});
		var rect = createElement('rect').attr({
		    class: 'ethchan'
		});

		g.append(rect);
		primaries.forEach(function (ent) {
		    var temp = ent[0].getBBox();
		    primBBoxes.push(temp);
		    contWidth += temp.width;
		});
		if (this.backup_adapter)
		    backup = this.backup_adapter.draw();

		contWidth += (numPrimaries - 1) * this.hSpacing;
		selfBBox.x = this.borderWidth + ((contWidth - selfBBox.width) / 2);
		selfBBox.y = y;
		selfEnt.attr({ transform: translate(selfBBox.x, y) });
		y += selfBBox.height + this.vSpacing;
		g.append(selfEnt);
		if (backup) {
		    backupBBox = backup[0].getBBox();
		    contWidth += this.hSpacing + backupBBox.width;
		    backup.attr({ transform: translate(x, y) });
		    backupBBox.x = x;
		    backupBBox.y = y;
		    x += backupBBox.width + this.hSpacing;
		    if (primHeight < backupBBox.height)
			primHeight = backupBBox.height;
		}
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
		x += this.borderWidth - this.hSpacing;
		y += this.borderWidth + primHeight;
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

		/* Hookup path to backup */
		if (backup)
		    g.append(createElement('line').attr({
			x1: selfBBox.x,
			y1: selfBBox.y + (selfBBox.height / 2),
			x2: backupBBox.x + (backupBBox.width / 2),
			y2: backupBBox.y
		    }));

		/**
		 * A jQuery object for the SVG group that represents
		 * this etherchannel.
		 * @type {SVGTree}
		 */
		this.svg = g;
		return g;
	    }
	};

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
	    this.entstat = "entstat not found";
	    temp = lpar.data;
	    if (temp) temp = temp['Netstat_v'];
	    if (temp) temp = temp[0];
	    if (temp) this.entstat = temp[this.name];
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
		var g = createElement('g').attr({
		    id: this.name,
		    class: 'ent'
		}).append(createElement('rect').attr({
		    width: this.width,
		    height: this.height
		})).append(createElement('text').attr({
		    x: 25,
		    y: 25
		}).append(this.name));

		/**
		 * A jQuery object for the SVG group that represents
		 * this ethernet adapter.
		 * @type {SVGTree}
		 */
		this.svg = g;
		return g;
	    }
	};

	window.snapper.world = new World();
    }
)(window, document);

$(document).ready(function () {
    window.snapper.world.draw();
    window.snapper.world.createInterconnects();
});
