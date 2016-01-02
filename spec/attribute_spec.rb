require "spec_helper"
require "attribute"

# Scenarios:
#   1. 0 PdAt and 0 CuAt is called z0
#   2. 0 PdAt and 1 CuAt is called z1
#   3. 0 PdAt and 2 CuAt is called z2
#   4. 1 PdAt and 0 CuAt is called o0
#   5. 1 PdAt and 1 CuAt is called o1
#   6. 1 PdAt and 2 CuAt is called o2
#   7. 2 PdAt and 0 CuAt is called t0
#   8. 2 PdAt and 1 CuAt is called t1
#   9. 2 PdAt and 2 CuAt is called t2
describe Attribute do
  let(:db) { Db.new }
  let(:pdat1) {
    Item.new(db).tap do |i|
      i['uniquetype'] = "adapter/pseudo/sea"
      i['attribute'] = "ha_mode"
      i['deflt'] = "disabled"
      i['values'] = "disabled,auto,standby,sharing"
      i['width'] = ""
      i['type'] = "R"
      i['generic'] = "DU"
      i['rep'] = "sl"
      i['nls_index'] = 88
    end
  }

  let(:pdat2) {
    Item.new(db).tap do |i|
      i['uniquetype'] = "adapter/pseudo/sea"
      i['attribute'] = "ha_mode"
      i['deflt'] = "sharing"
      i['values'] = "disabled,auto,standby,sharing"
      i['width'] = ""
      i['type'] = "R"
      i['generic'] = "DU"
      i['rep'] = "sl"
      i['nls_index'] = 88
    end
  }

  let(:cuat1) {
    Item.new(db).tap do |i|
      i['name'] = "ent22"
      i['attribute'] = "ha_mode"
      i['value'] = "auto"
      i['type'] = "R"
      i['generic'] = "DU"
      i['rep'] = "n"
      i['nls_index'] = 88
    end
  }

  let(:cuat2) {
    Item.new(db).tap do |i|
      i['name'] = "ent22"
      i['attribute'] = "ha_mode"
      i['value'] = "sharing"
      i['type'] = "R"
      i['generic'] = "DU"
      i['rep'] = "n"
      i['nls_index'] = 88
    end
  }

  let(:default_cuat) {
    Item.new(db).tap do |i|
      i['name'] = "ent22"
      i['attribute'] = "ha_mode"
      i['value'] = "disabled"
      i['type'] = "R"
      i['generic'] = "DU"
      i['rep'] = "n"
      i['nls_index'] = 88
    end
  }

  let(:z1) { Attribute.new([ cuat1 ], [])}
  let(:z2) { Attribute.new([ cuat1, cuat2 ], [])}
  let(:o0) { Attribute.new([], [ pdat1 ])}
  let(:o1) { Attribute.new([ cuat1 ], [ pdat1 ])}
  let(:o2) { Attribute.new([ cuat1, cuat2 ], [ pdat1 ])}
  let(:t0) { Attribute.new([], [ pdat1, pdat2 ])}
  let(:t1) { Attribute.new([ cuat1 ], [ pdat1, pdat2 ])}
  let(:t2) { Attribute.new([ cuat1, cuat2 ], [ pdat1, pdat2 ])}

  describe "#initialize" do
    it "raises an exception if both arguments are empty" do
      expect { Attribute.new([], []) }.to raise_error("Both cu_ats and pd_at can not be empty")
    end

    it "does not raise an exception in other cases" do
      expect { [ z1, z2, o0, o1, o2, t0, t1, t2 ] }.to_not raise_error
    end
  end

  describe "#cu_ats" do
    it "returns empty array if no CuAt entries were supplied" do
      expect(o0.cu_ats).to eq([])
      expect(t0.cu_ats).to eq([])
    end

    it "returns array of one element if one CuAt entry was supplied" do
      expect(z1.cu_ats).to eq([ cuat1 ])
      expect(o1.cu_ats).to eq([ cuat1 ])
      expect(t1.cu_ats).to eq([ cuat1 ])
    end

    it "returns array of two elements if two CuAt entries where supplied" do
      expect(z2.cu_ats).to eq([ cuat1, cuat2 ])
      expect(o2.cu_ats).to eq([ cuat1, cuat2 ])
      expect(t2.cu_ats).to eq([ cuat1, cuat2 ])
    end
  end

  describe "#cu_at" do
    it "returns nil if no CuAt entry was supplied" do
      expect(o0.cu_at).to be_nil
      expect(t0.cu_at).to be_nil
    end

    it "returns CuAt element if one was supplied" do
      expect(z1.cu_at).to eq(cuat1)
      expect(o1.cu_at).to eq(cuat1)
      expect(t1.cu_at).to eq(cuat1)
    end

    it "returns first CuAt element if more than one CuAt entries where supplied" do
      expect(z2.cu_at).to eq(cuat1)
      expect(o2.cu_at).to eq(cuat1)
      expect(t2.cu_at).to eq(cuat1)
    end
  end

  describe "#pd_ats" do
    it "returns empty array if no PdAt entries were supplied" do
      expect(z1.pd_ats).to eq([])
      expect(z2.pd_ats).to eq([])
    end

    it "returns array of one element if one PdAt entry was supplied" do
      expect(o0.pd_ats).to eq([ pdat1 ])
      expect(o1.pd_ats).to eq([ pdat1 ])
      expect(o2.pd_ats).to eq([ pdat1 ])
    end

    it "returns array of two elements if two PdAt entries where supplied" do
      expect(t0.pd_ats).to eq([ pdat1, pdat2 ])
      expect(t1.pd_ats).to eq([ pdat1, pdat2 ])
      expect(t2.pd_ats).to eq([ pdat1, pdat2 ])
    end
  end

  describe "#pd_at" do
    it "returns nil if no PdAt entries were supplied" do
      expect(z1.pd_at).to be_nil
      expect(z2.pd_at).to be_nil
    end

    it "returns PdAt element if one was supplied" do
      expect(o0.pd_at).to eq(pdat1)
      expect(o1.pd_at).to eq(pdat1)
      expect(o2.pd_at).to eq(pdat1)
    end

    it "returns the first PdAt element if more than one PdAt entries where supplied" do
      expect(t0.pd_at).to eq(pdat1)
      expect(t1.pd_at).to eq(pdat1)
      expect(t2.pd_at).to eq(pdat1)
    end
  end

  describe "#values" do
    it "returns empty array if no CuAt entries were supplied" do
      expect(o0.values).to eq([])
      expect(t0.values).to eq([])
    end

    it "returns array of CuAt value if one CuAt entry was supplied" do
      expect(z1.values).to eq([ "auto" ])
      expect(o1.values).to eq([ "auto" ])
      expect(t1.values).to eq([ "auto" ])
    end

    it "returns array with each CuAt value if two CuAt entries where supplied" do
      expect(z2.values).to eq([ "auto", "sharing" ])
      expect(o2.values).to eq([ "auto", "sharing" ])
      expect(t2.values).to eq([ "auto", "sharing" ])
    end
  end

  describe "#customized?" do
    it "returns false if no CuAt entries were supplied" do
      expect(o0.customized?).to be false
      expect(t0.customized?).to be false
    end

    it "returns false if all entries in values equal the PdAt deflt value" do
      attr = Attribute.new([ default_cuat ], [ pdat1 ])
      expect(attr.customized?).to be false
    end

    it "returns true when no PdAt entries are supplied" do
      expect(z1.customized?).to be true
      expect(z2.customized?).to be true
    end

    it "returns true if one CuAt element was supplied" do
      expect(o1.customized?).to be true
      expect(t1.customized?).to be true
    end

    it "returns true if more than one CuAt entries where supplied" do
      expect(o2.customized?).to be true
      expect(t2.customized?).to be true
    end
  end

  describe "#name" do
    it "returns nil when no CuAt entry was supplied" do
      expect(o0.name).to be_nil
      expect(t0.name).to be_nil
    end

    it "returns the name from the CuAt when one is supplied" do
      expect(z1.name).to eq("ent22")
      expect(o1.name).to eq("ent22")
      expect(t1.name).to eq("ent22")
    end

    it "returns the name from the first CuAt entry when more than one entries are supplied" do
      expect(z2.name).to eq("ent22")
      expect(o2.name).to eq("ent22")
      expect(t2.name).to eq("ent22")
    end
  end

  describe "#value" do
    it "returns the deflt from the PdAt entry when no CuAt entry is supplied" do
      expect(o0.value).to eq("disabled")
      expect(t0.value).to eq("disabled")
    end

    it "returns the value from the CuAt entry when one is supplied" do
      expect(z1.value).to eq("auto")
      expect(o1.value).to eq("auto")
      expect(t1.value).to eq("auto")
    end

    it "returns the value from the first CuAt entry when more than one are supplied" do
      expect(z2.value).to eq("auto")
      expect(o2.value).to eq("auto")
      expect(t2.value).to eq("auto")
    end
  end

  describe "#uniquetype" do
    it "returns nil if no PdAt entries were supplied" do
      expect(z1.uniquetype).to be_nil
      expect(z2.uniquetype).to be_nil
    end

    it "returns the uniquetype from the PdAt entry if one is supplied" do
      expect(o0.uniquetype).to eq("adapter/pseudo/sea")
      expect(o1.uniquetype).to eq("adapter/pseudo/sea")
      expect(o2.uniquetype).to eq("adapter/pseudo/sea")
    end

    it "returns the uniquetype from the first PdAt entry if more than one was supplied" do
      expect(t0.uniquetype).to eq("adapter/pseudo/sea")
      expect(t1.uniquetype).to eq("adapter/pseudo/sea")
      expect(t2.uniquetype).to eq("adapter/pseudo/sea")
    end
  end

  describe "#deflt" do
    it "returns nil if no PdAt entries were supplied" do
      expect(z1.deflt).to be_nil
      expect(z2.deflt).to be_nil
    end

    it "returns the deflt from the PdAt entry if one is supplied" do
      expect(o0.deflt).to eq("disabled")
      expect(o1.deflt).to eq("disabled")
      expect(o2.deflt).to eq("disabled")
    end

    it "returns the deflt from the first PdAt entry if more than one was supplied" do
      expect(t0.deflt).to eq("disabled")
      expect(t1.deflt).to eq("disabled")
      expect(t2.deflt).to eq("disabled")
    end
  end

  describe "#width" do
    it "returns nil if no PdAt entries were supplied" do
      expect(z1.width).to be_nil
      expect(z2.width).to be_nil
    end

    it "returns the width from the PdAt entry if one is supplied" do
      expect(o0.width).to eq("")
      expect(o1.width).to eq("")
      expect(o2.width).to eq("")
    end

    it "returns the width from the first PdAt entry if more than one was supplied" do
      expect(t0.width).to eq("")
      expect(t1.width).to eq("")
      expect(t2.width).to eq("")
    end
  end

  describe "#pd_at_values" do
    it "returns nil if no PdAt entries were supplied" do
      expect(z1.pd_at_values).to be_nil
      expect(z2.pd_at_values).to be_nil
    end

    it "returns the values from the PdAt entry if one is supplied" do
      expect(o0.pd_at_values).to eq("disabled,auto,standby,sharing")
      expect(o1.pd_at_values).to eq("disabled,auto,standby,sharing")
      expect(o2.pd_at_values).to eq("disabled,auto,standby,sharing")
    end

    it "returns the values from the first PdAt entry if more than one was supplied" do
      expect(t0.pd_at_values).to eq("disabled,auto,standby,sharing")
      expect(t1.pd_at_values).to eq("disabled,auto,standby,sharing")
      expect(t2.pd_at_values).to eq("disabled,auto,standby,sharing")
    end
  end

  describe "#attribute" do
    it "always returns the name of the attribute in all cases" do
      expect(z1.attribute).to eq("ha_mode")
      expect(z2.attribute).to eq("ha_mode")
      expect(o0.attribute).to eq("ha_mode")
      expect(o1.attribute).to eq("ha_mode")
      expect(o2.attribute).to eq("ha_mode")
      expect(t0.attribute).to eq("ha_mode")
      expect(t1.attribute).to eq("ha_mode")
      expect(t2.attribute).to eq("ha_mode")
    end
  end

  describe "#generic" do
    it "always returns the generic field in all cases" do
      expect(z1.generic).to eq("DU")
      expect(z2.generic).to eq("DU")
      expect(o0.generic).to eq("DU")
      expect(o1.generic).to eq("DU")
      expect(o2.generic).to eq("DU")
      expect(t0.generic).to eq("DU")
      expect(t1.generic).to eq("DU")
      expect(t2.generic).to eq("DU")
    end
  end

  describe "#nls_index" do
    it "always returns the nls_index field in all cases" do
      expect(z1.nls_index).to eq(88)
      expect(z2.nls_index).to eq(88)
      expect(o0.nls_index).to eq(88)
      expect(o1.nls_index).to eq(88)
      expect(o2.nls_index).to eq(88)
      expect(t0.nls_index).to eq(88)
      expect(t1.nls_index).to eq(88)
      expect(t2.nls_index).to eq(88)
    end
  end

  describe "#rep" do
    it "always return the rep field in all cases" do
      expect(z1.rep).to eq("n")
      expect(z2.rep).to eq("n")
      expect(o0.rep).to eq("sl")
      expect(o1.rep).to eq("sl")
      expect(o2.rep).to eq("sl")
      expect(t0.rep).to eq("sl")
      expect(t1.rep).to eq("sl")
      expect(t2.rep).to eq("sl")
    end
  end

  describe "#type" do
    it "always returns the type field in all cases" do
      expect(z1.type).to eq("R")
      expect(z2.type).to eq("R")
      expect(o0.type).to eq("R")
      expect(o1.type).to eq("R")
      expect(o2.type).to eq("R")
      expect(t0.type).to eq("R")
      expect(t1.type).to eq("R")
      expect(t2.type).to eq("R")
    end
  end
end
