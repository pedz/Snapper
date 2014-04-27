
(function (window, document, undefined) {

    function render(bag) {
	if (bag instanceof Array) {
	    bag.forEach(function (obj, index) {
		obj.draw();
	    });
	} else {
	    Object.getOwnPropertyNames(bag).forEach(function (id, index) {
		bag[id].draw();
	    });
	}
    }

    function xxx(attr, value) {
	return function (obj) {
	    return (obj[attr] == value);
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
	draw: function () {
	    console.log("draw", this.name);
	    render(this.cecs);
	},

	/* data is assumed to be for a single LPAR from a single snap */
	addSnap: function (data) {
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
	    this.draw();
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
	draw: function () {
	    console.log("draw CEC", this.name);
	    render(this.lpars);
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
	this.hostname = this.name =
	    this.cuat.filter(xxx('name', 'inet0')).filter(xxx('attribute', 'hostname'))[0]['value'];
	console.log("LPAR", id, "is", this.name);
	this.seas = this.cudv.filter(xxx('ddins', 'seadd')).map(function (cudv) {
	    return new SEA(this, cudv);
	}, this);
    }
	
    LPAR.prototype = {
	draw: function() {
	    console.log("draw LPAR", this.name);
	    render(this.seas);
	}
    }
	
    /* Constructor */
    function SEA(lpar, cudv) {
	if (this === window) {
	    return new SEA(lpar, cudv);
	}
	this.name = cudv['name'];
	console.log("new SEA", this.name);
	    
	this.lpar = lpar;
	this.cudv = cudv;
    }
	    
    SEA.prototype = {
	draw: function() {
	    console.log("draw SEA", this.name);
	}
    }
    
    window.snapper.world = new World();
})(window, document);
