var afterAll, afterEach, beforeAll, beforeEach, describe, expect, it;

describe("snapper", function() {
    it("has a Padding constructor", function() {
	expect(typeof window.snapper.Padding).toBe("function");
	expect(typeof window.snapper.Padding.prototype).toBe("object");
    });
    it("has a HLayoutBox constructor", function() {
	expect(typeof window.snapper.HLayoutBox).toBe("function");
	expect(typeof window.snapper.HLayoutBox.prototype).toBe("object");
    });
    it("has a VLayoutBox constructor", function() {
	expect(typeof window.snapper.VLayoutBox).toBe("function");
	expect(typeof window.snapper.VLayoutBox.prototype).toBe("object");
    });
    it("has a World constructor", function() {
	expect(typeof window.snapper.World).toBe("function");
	expect(typeof window.snapper.World.prototype).toBe("object");
    });
    it("has a CEC constructor", function() {
	expect(typeof window.snapper.CEC).toBe("function");
	expect(typeof window.snapper.CEC.prototype).toBe("object");
    });
    it("has a LPAR constructor", function() {
	expect(typeof window.snapper.LPAR).toBe("function");
	expect(typeof window.snapper.LPAR.prototype).toBe("object");
    });
    it("has a Ifnet constructor", function() {
	expect(typeof window.snapper.Ifnet).toBe("function");
	expect(typeof window.snapper.Ifnet.prototype).toBe("object");
    });
    it("has a Device constructor", function() {
	expect(typeof window.snapper.Device).toBe("function");
	expect(typeof window.snapper.Device.prototype).toBe("object");
    });
    it("has a SEA constructor", function() {
	expect(typeof window.snapper.SEA).toBe("function");
	expect(typeof window.snapper.SEA.prototype).toBe("object");
    });
    it("has a EthChan constructor", function() {
	expect(typeof window.snapper.EthChan).toBe("function");
	expect(typeof window.snapper.EthChan.prototype).toBe("object");
    });
    it("has a Ent constructor", function() {
	expect(typeof window.snapper.Ent).toBe("function");
	expect(typeof window.snapper.Ent.prototype).toBe("object");
    });
    it("has a VirtualSwitch constructor", function() {
	expect(typeof window.snapper.VirtualSwitch).toBe("function");
	expect(typeof window.snapper.VirtualSwitch.prototype).toBe("object");
    });
    it("has a Attribute constructor", function() {
	expect(typeof window.snapper.Attribute).toBe("function");
	expect(typeof window.snapper.Attribute.prototype).toBe("object");
    });

    it("has a world object", function() {
	expect(typeof window.snapper.world).toBe("object");
	expect(window.snapper.world instanceof window.snapper.World).toBe(true);
    });
});
