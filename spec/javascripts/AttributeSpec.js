var afterAll, afterEach, beforeAll, beforeEach, describe, expect, it;

describe("attribute", function() {
    var Attribute = window.snapper.Attribute;
    var pdat1;
    var pdat2;
    var cuat1;
    var cuat2;
    var default_cuat;
    var z1, z2;
    var o0, o1, o2;
    var t0, t1, t2;

    beforeAll(function () {
	pdat1 = {
	    uniquetype: "adapter/pseudo/sea",
	    attribute: "ha_mode",
	    deflt: "disabled",
	    values: "disabled,auto,standby,sharing",
	    width: "",
	    type: "R",
	    generic: "DU",
	    rep: "sl",
	    nls_index: 88
	};

	pdat2 = {
	    uniquetype: "adapter/pseudo/sea",
	    attribute: "ha_mode",
	    deflt: "sharing",
	    values: "disabled,auto,standby,sharing",
	    width: "",
	    type: "R",
	    generic: "DU",
	    rep: "sl",
	    nls_index: 88
	};
	
	cuat1 = {
	    name: "ent22",
	    attribute: "ha_mode",
	    value: "auto",
	    type: "R",
	    generic: "DU",
	    rep: "n",
	    nls_index: 88
	};
	
	cuat2 = {
	    name: "ent22",
	    attribute: "ha_mode",
	    value: "sharing",
	    type: "R",
	    generic: "DU",
	    rep: "n",
	    nls_index: 88
	};
	
	default_cuat = {
	    name: "ent22",
	    attribute: "ha_mode",
	    value: "disabled",
	    type: "R",
	    generic: "DU",
	    rep: "n",
	    nls_index: 88
	};
	
	z1 = new Attribute([ cuat1 ], []);
	z2 = new Attribute([ cuat1, cuat2 ], []);
	o0 = new Attribute([], [ pdat1 ]);
	o1 = new Attribute([ cuat1 ], [ pdat1 ]);
	o2 = new Attribute([ cuat1, cuat2 ], [ pdat1 ]);
	t0 = new Attribute([], [ pdat1, pdat2 ]);
	t1 = new Attribute([ cuat1 ], [ pdat1, pdat2 ]);
	t2 = new Attribute([ cuat1, cuat2 ], [ pdat1, pdat2 ]);
    });

    describe("#initialize", function () {
	it("raises an exception if both arguments are empty", function () {
	    var both_empty = function() {
		new Attribute([], []);
	    };
	    var cu_ats_null = function() {
		new Attribute(null, []);
	    };
	    var pd_ats_null = function() {
		new Attribute([], null);
	    };
	    var cu_ats_obj = function() {
		new Attribute({}, []);
	    };
	    var pd_ats_obj = function() {
		new Attribute([], {});
	    };
	    expect(both_empty).toThrowError(TypeError, "Both cu_ats and pd_ats can not be empty");
	    expect(cu_ats_null).toThrowError(TypeError, "Both cu_ats and pd_ats can not be empty");
	    expect(pd_ats_null).toThrowError(TypeError, "Both cu_ats and pd_ats can not be empty");
	    expect(cu_ats_obj).toThrowError(TypeError, "cu_ats is not an array");
	    expect(pd_ats_obj).toThrowError(TypeError, "pd_ats is not an array");
	});
    });

    describe("#cu_ats", function () {
	it("returns empty array if no CuAt entries were supplied", function () {
	    expect(o0.cu_ats).toEqual([]);
	    expect(t0.cu_ats).toEqual([]);
	});

	it("returns array of one element if one CuAt entry was supplied", function () {
	    expect(z1.cu_ats).toEqual([ cuat1 ]);
	    expect(o1.cu_ats).toEqual([ cuat1 ]);
	    expect(t1.cu_ats).toEqual([ cuat1 ]);
	});

	it("returns array of two elements if two CuAt entries where supplied", function () {
	    expect(z2.cu_ats).toEqual([ cuat1, cuat2 ]);
	    expect(o2.cu_ats).toEqual([ cuat1, cuat2 ]);
	    expect(t2.cu_ats).toEqual([ cuat1, cuat2 ]);
	});
    });


    describe("#cu_at", function () {
	it("returns nil if no CuAt entry was supplied", function () {
	    expect(o0.cu_at).toBe(undefined);
	    expect(t0.cu_at).toBe(undefined);
	});
	
	it("returns CuAt element if one was supplied", function () {
	    expect(z1.cu_at).toEqual(cuat1);
	    expect(o1.cu_at).toEqual(cuat1);
	    expect(t1.cu_at).toEqual(cuat1);
	});
	
	it("returns first CuAt element if more than one CuAt entries where supplied", function () {
	    expect(z2.cu_at).toEqual(cuat1);
	    expect(o2.cu_at).toEqual(cuat1);
	    expect(t2.cu_at).toEqual(cuat1);
	});
    });
    
    describe("#pd_ats", function () {
	it("returns empty array if no PdAt entries were supplied", function () {
	    expect(z1.pd_ats).toEqual([]);
	    expect(z2.pd_ats).toEqual([]);
	});
	
	it("returns array of one element if one PdAt entry was supplied", function () {
	    expect(o0.pd_ats).toEqual([ pdat1 ]);
	    expect(o1.pd_ats).toEqual([ pdat1 ]);
	    expect(o2.pd_ats).toEqual([ pdat1 ]);
	});
	
	it("returns array of two elements if two PdAt entries where supplied", function () {
	    expect(t0.pd_ats).toEqual([ pdat1, pdat2 ]);
	    expect(t1.pd_ats).toEqual([ pdat1, pdat2 ]);
	    expect(t2.pd_ats).toEqual([ pdat1, pdat2 ]);
	});
    });
    
    describe("#pd_at", function () {
	it("returns nil if no PdAt entries were supplied", function () {
	    expect(z1.pd_at).toBe(undefined);
	    expect(z2.pd_at).toBe(undefined);
	});
	
	it("returns PdAt element if one was supplied", function () {
	    expect(o0.pd_at).toEqual(pdat1);
	    expect(o1.pd_at).toEqual(pdat1);
	    expect(o2.pd_at).toEqual(pdat1);
	});
	
	it("returns the first PdAt element if more than one PdAt entries where supplied", function () {
	    expect(t0.pd_at).toEqual(pdat1);
	    expect(t1.pd_at).toEqual(pdat1);
	    expect(t2.pd_at).toEqual(pdat1);
	});
    });
    
    describe("#values", function () {
	it("returns empty array if no CuAt entries were supplied", function () {
	    expect(o0.values).toEqual([]);
	    expect(t0.values).toEqual([]);
	});
	
	it("returns array of CuAt value if one CuAt entry was supplied", function () {
	    expect(z1.values).toEqual([ "auto" ]);
	    expect(o1.values).toEqual([ "auto" ]);
	    expect(t1.values).toEqual([ "auto" ]);
	});
	
	it("returns array with each CuAt value if two CuAt entries where supplied", function () {
	    expect(z2.values).toEqual([ "auto", "sharing" ]);
	    expect(o2.values).toEqual([ "auto", "sharing" ]);
	    expect(t2.values).toEqual([ "auto", "sharing" ]);
	});
    });
    
    describe("#customized", function () {
	it("returns false if no CuAt entries were supplied", function () {
	    expect(o0.customized).toBe(false);
	    expect(t0.customized).toBe(false);
	});
	
	it("returns false if all entries in values equal the PdAt deflt value", function () {
	    attr = new Attribute([ default_cuat ], [ pdat1 ]);
	    expect(attr.customized).toBe(false);
	});
	
	it("returns true when no PdAt entries are supplied", function () {
	    expect(z1.customized).toBe(true);
	    expect(z2.customized).toBe(true);
	});
	
	it("returns true if one CuAt element was supplied", function () {
	    expect(o1.customized).toBe(true);
	    expect(t1.customized).toBe(true);
	});
	
	it("returns true if more than one CuAt entries where supplied", function () {
	    expect(o2.customized).toBe(true);
	    expect(t2.customized).toBe(true);
	});
    });
    
    describe("#name", function () {
	it("returns nil when no CuAt entry was supplied", function () {
	    expect(o0.name).toBe(null);
	    expect(t0.name).toBe(null);
	});
	
	it("returns the name from the CuAt when one is supplied", function () {
	    expect(z1.name).toEqual("ent22");
	    expect(o1.name).toEqual("ent22");
	    expect(t1.name).toEqual("ent22");
	});
	
	it("returns the name from the first CuAt entry when more than one entries are supplied", function () {
	    expect(z2.name).toEqual("ent22");
	    expect(o2.name).toEqual("ent22");
	    expect(t2.name).toEqual("ent22");
	});
    });
    
    describe("#value", function () {
	it("returns the deflt from the PdAt entry when no CuAt entry is supplied", function () {
	    expect(o0.value).toEqual("disabled");
	    expect(t0.value).toEqual("disabled");
	});
	
	it("returns the value from the CuAt entry when one is supplied", function () {
	    expect(z1.value).toEqual("auto");
	    expect(o1.value).toEqual("auto");
	    expect(t1.value).toEqual("auto");
	});
	
	it("returns the value from the first CuAt entry when more than one are supplied", function () {
	    expect(z2.value).toEqual("auto");
	    expect(o2.value).toEqual("auto");
	    expect(t2.value).toEqual("auto");
	});
    });
    
    describe("#uniquetype", function () {
	it("returns nil if no PdAt entries were supplied", function () {
	    expect(z1.uniquetype).toBe(null);
	    expect(z2.uniquetype).toBe(null);
	});
	
	it("returns the uniquetype from the PdAt entry if one is supplied", function () {
	    expect(o0.uniquetype).toEqual("adapter/pseudo/sea");
	    expect(o1.uniquetype).toEqual("adapter/pseudo/sea");
	    expect(o2.uniquetype).toEqual("adapter/pseudo/sea");
	});
	
	it("returns the uniquetype from the first PdAt entry if more than one was supplied", function () {
	    expect(t0.uniquetype).toEqual("adapter/pseudo/sea");
	    expect(t1.uniquetype).toEqual("adapter/pseudo/sea");
	    expect(t2.uniquetype).toEqual("adapter/pseudo/sea");
	});
    });
    
    describe("#deflt", function () {
	it("returns nil if no PdAt entries were supplied", function () {
	    expect(z1.deflt).toBe(null);
	    expect(z2.deflt).toBe(null);
	});
	
	it("returns the deflt from the PdAt entry if one is supplied", function () {
	    expect(o0.deflt).toEqual("disabled");
	    expect(o1.deflt).toEqual("disabled");
	    expect(o2.deflt).toEqual("disabled");
	});
	
	it("returns the deflt from the first PdAt entry if more than one was supplied", function () {
	    expect(t0.deflt).toEqual("disabled");
	    expect(t1.deflt).toEqual("disabled");
	    expect(t2.deflt).toEqual("disabled");
	});
    });
    
    describe("#width", function () {
	it("returns nil if no PdAt entries were supplied", function () {
	    expect(z1.width).toBe(null);
	    expect(z2.width).toBe(null);
	});
	
	it("returns the width from the PdAt entry if one is supplied", function () {
	    expect(o0.width).toEqual("");
	    expect(o1.width).toEqual("");
	    expect(o2.width).toEqual("");
	});
	
	it("returns the width from the first PdAt entry if more than one was supplied", function () {
	    expect(t0.width).toEqual("");
	    expect(t1.width).toEqual("");
	    expect(t2.width).toEqual("");
	});
    });
    
    describe("#pd_at_values", function () {
	it("returns nil if no PdAt entries were supplied", function () {
	    expect(z1.pd_at_values).toBe(null);
	    expect(z2.pd_at_values).toBe(null);
	});
	
	it("returns the values from the PdAt entry if one is supplied", function () {
	    expect(o0.pd_at_values).toEqual("disabled,auto,standby,sharing");
	    expect(o1.pd_at_values).toEqual("disabled,auto,standby,sharing");
	    expect(o2.pd_at_values).toEqual("disabled,auto,standby,sharing");
	});
	
	it("returns the values from the first PdAt entry if more than one was supplied", function () {
	    expect(t0.pd_at_values).toEqual("disabled,auto,standby,sharing");
	    expect(t1.pd_at_values).toEqual("disabled,auto,standby,sharing");
	    expect(t2.pd_at_values).toEqual("disabled,auto,standby,sharing");
	});
    });
    
    describe("#attribute", function () {
	it("always returns the name of the attribute in all cases", function () {
	    expect(z1.attribute).toEqual("ha_mode");
	    expect(z2.attribute).toEqual("ha_mode");
	    expect(o0.attribute).toEqual("ha_mode");
	    expect(o1.attribute).toEqual("ha_mode");
	    expect(o2.attribute).toEqual("ha_mode");
	    expect(t0.attribute).toEqual("ha_mode");
	    expect(t1.attribute).toEqual("ha_mode");
	    expect(t2.attribute).toEqual("ha_mode");
	});
    });
    
    describe("#generic", function () {
	it("always returns the generic field in all cases", function () {
	    expect(z1.generic).toEqual("DU");
	    expect(z2.generic).toEqual("DU");
	    expect(o0.generic).toEqual("DU");
	    expect(o1.generic).toEqual("DU");
	    expect(o2.generic).toEqual("DU");
	    expect(t0.generic).toEqual("DU");
	    expect(t1.generic).toEqual("DU");
	    expect(t2.generic).toEqual("DU");
	});
    });
    
    describe("#nls_index", function () {
	it("always returns the nls_index field in all cases", function () {
	    expect(z1.nls_index).toEqual(88);
	    expect(z2.nls_index).toEqual(88);
	    expect(o0.nls_index).toEqual(88);
	    expect(o1.nls_index).toEqual(88);
	    expect(o2.nls_index).toEqual(88);
	    expect(t0.nls_index).toEqual(88);
	    expect(t1.nls_index).toEqual(88);
	    expect(t2.nls_index).toEqual(88);
	});
    });
    
    describe("#rep", function () {
	it("always return the rep field in all cases", function () {
	    expect(z1.rep).toEqual("n");
	    expect(z2.rep).toEqual("n");
	    expect(o0.rep).toEqual("sl");
	    expect(o1.rep).toEqual("sl");
	    expect(o2.rep).toEqual("sl");
	    expect(t0.rep).toEqual("sl");
	    expect(t1.rep).toEqual("sl");
	    expect(t2.rep).toEqual("sl");
	});
    });
    
    describe("#type", function () {
	it("always returns the type field in all cases", function () {
	    expect(z1.type).toEqual("R");
	    expect(z2.type).toEqual("R");
	    expect(o0.type).toEqual("R");
	    expect(o1.type).toEqual("R");
	    expect(o2.type).toEqual("R");
	    expect(t0.type).toEqual("R");
	    expect(t1.type).toEqual("R");
	    expect(t2.type).toEqual("R");
	});
    });
});
