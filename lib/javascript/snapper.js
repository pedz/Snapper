
(function createEnvironment(window, document, undefined) {
    var svgNamespaceURI = "http://www.w3.org/2000/svg";
    var svgSelection;
    var svgElement;		// some svg element in the page

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

    function line(p1, p2) {
	var l = createElement('line');
	var e = l[0];
	e.setAttributeNS(null, 'x1', p1.x);
	e.setAttributeNS(null, 'y1', p1.y);
	e.setAttributeNS(null, 'x2', p2.x);
	e.setAttributeNS(null, 'y2', p2.y);
	return l;
    }

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

    function translate(x, y) {
	return 'translate(' + x + ', ' + y + ')';
    }

    /* Passed either an array of items to render or a hash whose values need to be rendered */
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

    function World() {
	if (this === window) {
	    return new World();
	}

	this.name = "World";
	this.cecs = {};
	this.snaps = [];
    }

    World.prototype = {
	/*
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

	draw: function drawFoWorld() {
	    console.log("draw", this.name);
	    var x = 0, y = 0;
	    var g = createElement('g').attr({
		id: this.name,
		class: 'world'
	    });
	    render(this.cecs).forEach(function transformAndAppendCEC(cec) {
		g.append(cec.attr({ transform: translate(x, y) }));
		x += 20;
	    });
	    this.svg = g;
	    $('svg').append(g);
	},

	/* data is assumed to be for a single LPAR from a single snap */
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

	    var system_id_attrs = sys0_attrs.filter(function (cuat) { return cuat['attribute'] == "id_to_system"; });
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

    /* Constructor */
    function CEC(world, id) {
	if (this === window) {
	    return new CEC(id);
	}

	console.log("new CEC", id);
	this.world = world;
	this.id = id;
	this.name = id;
	this.data = [];
	this.lpars = {};
    }

    CEC.prototype = {
	hSpacing: 50,
	vSpacing: 50,

	/*
	 * Eventually this will need to create the interconnects
	 * within the CEC such as between LPARs and the virtual
	 * switches.
	 */
	createInterconnects: function createInterconnectsForCEC() {
	    Object.getOwnPropertyNames(this.lpars).forEach(function (id) {
		this.lpars[id].createInterconnects();
	    }, this);
	},

	draw: function drawForCEC() {
	    console.log("draw CEC", this.name);
	    var x = this.hSpacing, y = this.vSpacing, max_height = 0;
	    var g = createElement('g').attr({
		id: this.name,
		class: 'cec'
	    });
	    render(this.lpars).forEach(function (lpar) {
		var bbox = lpar[0].getBBox();

		g.append(lpar.attr({ transform: translate(x, y) }));
		x += bbox.width + this.hSpacing;
		if (max_height < bbox.height)
		    max_height = bbox.height;
		svgSelection.attr({ width: x, height: max_height + (2 * this.vSpacing) });
	    }, this);
	    return (this.svg = g);
	},

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

	    var partition_id_attrs = sys0_attrs.filter(function (cuat) { return cuat['attribute'] == "id_to_partition"; });
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
    }

    /* Constructor */
    function LPAR(cec, id, data) {
	if (this === window) {
	    return new LPAR(cec, id);
	}
	console.log("new LPAR", id);

	this.cec = cec;
	this.id = id;
	this.data = data;
	this.cuat = data['CuAt'];
	this.cudv = data['CuDv'];
	this.pdat = data['PdAt'];
	this.pddv = data['PdDv'];
	this.devices = {
	    byName: {},
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

	this.hostname = this.name =
	    this.devices.byName['inet0'].attributes['hostname'].values[0]['value']
	console.log("LPAR", id, "is", this.name);
	this.seas = this.devices.byType['adapter/pseudo/sea'].map(function (device) {
	    return new SEA(this, device);
	}, this);
    }
	
    LPAR.prototype = {
	hSpacing: 50,
	vSpacing: 50,

	/* 
	 * I can't see what this will need to do other than call its
	 * dependents.
	 */
	createInterconnects: function createInterconnectsForLPAR() {
	    this.seas.forEach(function (sea) {
		sea.createInterconnects();
	    });
	},

	draw: function drawForLPAR() {
	    console.log("draw LPAR", this.name);
	    var x = 0, y = 0;
	    var g = createElement('g').attr({
		id: this.name,
		class: 'lpar'
	    });
	    render(this.seas).forEach(function (sea) {
		var bbox = sea[0].getBBox();

		g.append(sea.attr({ transform: translate(x, y) }));
		x += bbox.width + this.hSpacing;
	    }, this);
	    return (this.svg = g);
	}
    }
	
    function Device(lpar, cudv, data) {
	var uniquetype = cudv['PdDvLn'];
	var name = cudv['name'];

	/* console.log("new Device", name); */
	this.lpar = lpar;
	this.cudv = cudv;
	this.data = data;
	this.name = name;
	this.uniquetype = uniquetype;

	this.pddv = data['PdDv'].filter(function (pddv) { return pddv['uniquetype'] == uniquetype; })[0];
	this.pdat = data['PdAt'].filter(function (pdat) { return pdat['uniquetype'] == uniquetype; });
	this.cuat = data['CuAt'].filter(function (cuat) { return cuat['name'] == name; });

	this.attributes = {};
	/* Set up an attribute for each PdAt entry -- should be only one PdAt entry per attribute */
	this.pdat.forEach(function (pdat) {
	    this.attributes[pdat['attribute']] = {
		pdat: pdat,
		values: []
	    }
	}, this);
	/* Now fill in values array from customized attributes */
	this.cuat.forEach(function (cuat) {
	    var attribute = this.attributes[cuat['attribute']];
	    if (typeof attribute === 'undefined') // rare but it does happen
		attribute = (this.attributes[cuat['attribute']] = { values: [] });
	    attribute.values.push(cuat);
	}, this);
    }

    Device.prototype = {
	isSEA: function () {
	    return this.pddv['DvDr'] === "seadd";
	},

	isEthChan: function () {
	    return this.pddv['DvDr'] === "ethchandd";
	},

	isVEA: function () {
	    return this.pddv['DvDr'] === "vioentdd";
	},

	isEnt: function () {
	    return this.pddv['prefix'] === "ent";
	}
    }

    /* Constructor */
    function SEA(lpar, device) {
	if (this === window) {
	    return new SEA(lpar, device);
	}

	this.name = device.name;
	console.log("new SEA", this.name);
	    
	this.lpar = lpar;
	this.device = device;
	this.ent = new Ent(lpar, this, device);
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
			return new EthChan(this.lpar, this, device);
		    else
			return new Ent(this.lpar, this, device);
		}, this);
	}, this);

	this.ctl_chan = this.ctl_chan[0];
	this.real_adapter = this.real_adapter[0];
	var pvid_adapter = device.attributes['pvid_adapter'].values[0]['value'];
	this.virt_adapters.forEach(function (vea) {
	    if (vea.name == pvid_adapter)
		this.pvid_adapter = vea;
	}, this);
    }
	    
    SEA.prototype = {
	hSpacing: 50,
	vSpacing: 50,

	/*
	 * This needs to draw the interconnects between the various
	 * pieces of the SEA.
	 */
	createInterconnects: function createInterconnectsForSEA() {
	    if (this.real_adapter.device.isEthChan()) {
		this.real_adapter.createInterconnects();
	    }

	    var realBBox = this.real_adapter.device.ent.svg[0].getBBox();
	    var realCTM = this.real_adapter.device.ent.svg[0].getCTM();

	    var selfBBox = this.ent.svg[0].getBBox();
	    var selfCTM = this.ent.svg[0].getCTM();

	    var virtBBoxes = this.virt_adapters.map(function (vea) {
		return vea.device.ent.svg[0].getBBox();
	    }, this);
	    var virtCTMs = this.virt_adapters.map(function (vea) {
		return vea.device.ent.svg[0].getCTM();
	    }, this);
	    var virt_delta = selfBBox.width / this.virt_adapters.length;

	    var ctlBBox;
	    var ctlCTM;

	    var p1 = svgElement.createSVGPoint();
	    var p2 = svgElement.createSVGPoint();
	    var p3 = svgElement.createSVGPoint();

	    /* Midway across the top */
	    p1.x = realBBox.width / 2;
	    p1.y = 0;
	    p1 = p1.matrixTransform(realCTM);

	    /* Midway across the bottom */
	    p2.x = selfBBox.width / 2;
	    p2.y = selfBBox.height;
	    p2 = p2.matrixTransform(selfCTM);
	    svgSelection.append(line(p1, p2));

	    /* Do Virtuals */
	    this.virt_adapters.forEach(function (vea, index) {
		/* points accross top of self */
		p1.x = virt_delta * ( index + 0.5 );
		p1.y = 0;
		p1 = p1.matrixTransform(selfCTM);
		/* Middle of bottom of virt */
		p2.x = virtBBoxes[index].width / 2;
		p2.y = selfBBox.height;
		p2 = p2.matrixTransform(virtCTMs[index]);
		svgSelection.append(line(p1, p2));
	    }, this);

	    /* Control channel is a polyline */
	    if (this.ctl_chan) {
		ctlBBox = this.ctl_chan.device.ent.svg[0].getBBox();
		ctlCTM = this.ctl_chan.device.ent.svg[0].getCTM();
		/* start at middle of right side of self */
		p1.x = selfBBox.width;
		p1.y = selfBBox.height / 2;
		p1 = p1.matrixTransform(selfCTM);

		/* end at middle of bottom of control */
		p3.x = ctlBBox.width / 2;
		p3.y = ctlBBox.height;
		p3 = p3.matrixTransform(ctlCTM);

		/* corner is down from p3 and over from p1 */
		p2.x = p3.x;
		p2.y = p1.y;
		svgSelection.append(polyline(p1, p2, p3));
	    }
	},

	draw: function drawForSEA() {
	    var g = createElement('g').attr({
		class: 'sea'
	    });
	    /* vea_* is for all VEAs including the control channel */
	    var vea_x = 0, vea_y = 0, vea_height = 0, vea_shift = 0;
	    /* virt_width is the width of the virtual adapters excluding the control channel */
	    var virt_width;
	    var virtuals = render(this.virt_adapters);
	    var virtBBoxes = [];
	    var selfEnt = this.ent.draw();
	    var selfBBox = selfEnt[0].getBBox();
	    var realEnt = this.real_adapter.draw();
	    var realBBox = realEnt[0].getBBox();
	    var ctlEnt, ctlBBox;
	    var maxWidth = 0;
	    
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
		vea_x = virtBBoxes[index].width + this.hSpacing;
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
	    return (this.svg = g);
	}
    }
    
    function EthChan(lpar, parent, device) {
	if (this === window) {
	    return new EthChan(lpar, parent, device);
	}

	this.name = device.name;
	console.log("new EthChan", this.name);

	this.lpar = lpar;
	this.parent = parent;
	this.device = device;
	this.ent = new Ent(lpar, this, device);
	[ "adapter_names", "backup_adapter" ].forEach(function (attr) {
	    var values = device.attributes[attr].values;

	    if (values.length == 0)
		this[attr] = [];
	    else
		this[attr] = values[0]['value'].split(',').map(function (devName) {
		    var device = this.lpar.devices.byName[devName];
		    if (typeof device === 'undefined')
			alert("SEA ctor: device " + devName + " not found in parent LPAR " + lpar.name);
		    return new Ent(this.lpar, this, device);
		}, this);
	}, this);
	this.backup_adapter = this.backup_adapter[0];
    }

    EthChan.prototype = {
	hSpacing: 50,		// space between contained Ents
	vSpacing: 50,		// vertical spacing
	borderWidth: 10,

	/*
	 * Currently, this does nothing since the interconnects are
	 * created at draw time.
	 */
	createInterconnects: function createInterconnectsForEthChan() {
	    return;
	},

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
	    return (this.svg = g);
	}
    }

    function Ent(lpar, parent, device) {
	if (this === window) {
	    return new Ent(lpar, parent, device);
	}

	this.lpar = lpar;
	this.parent = parent;
	this.device = device;
	device.ent = this;
	this.name = device.name;
    }

    Ent.prototype = {
	width: 50,
	height: 50,

	/*
	 * I can't imagine this ever needing to do something.
	 */
	createInterconnects: function createInterconnectsForEnt() {
	    return;
	},

	draw: function drawForEnt() {
	    return (this.svg = createElement('g').attr({
		id: this.name,
		class: 'ent'
	    }).append(createElement('rect').attr({
		width: this.width,
		height: this.height
	    })).append(createElement('text').attr({
		x: 25,
		y: 25
	    }).append(this.name)));
	}
    }

    window.snapper.world = new World();
})(window, document);

$(document).ready(function () {
    window.snapper.world.draw();
    window.snapper.world.createInterconnects();
});
