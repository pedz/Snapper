require "spec_helper"
require "seas"

describe Seas::VeaConfig, :batch_dsl do
  describe "#==" do
    it "should be true for two VEAs with same PVIDs" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 1)
      vea2 = new_vea(pvid: 1)
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 == vc2).to be true
    end

    it "should be false for two VEAs with different PVIDs" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 1)
      vea2 = new_vea(pvid: 2)
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 == vc2).to be false
    end

    it "should be false for two VEAs with different vswitch" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 1, vswitch: "vs1")
      vea2 = new_vea(pvid: 1, vswitch: "vs2")
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 == vc2).to be false
    end

    it "should be false for two VEAs with allowed VLANs" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 1, allowed: [ 8, 9 ])
      vea2 = new_vea(pvid: 1, allowed: [ 8, 10 ])
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 == vc2).to be false
    end
  end

  describe "#<=>" do
    it "returns -1 if the left is smaller" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 1)
      vea2 = new_vea(pvid: 2)
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 <=> vc2).to be -1
    end

    it "returns 0 if the two match up" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 1)
      vea2 = new_vea(pvid: 1)
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 <=> vc2).to be 0
    end

    it "returns 1 if the left is larger" do
      not_used = start_new_snap
      vea1 = new_vea(pvid: 2)
      vea2 = new_vea(pvid: 1)
      vc1 = Seas::VeaConfig.new(vea1)
      vc2 = Seas::VeaConfig.new(vea2)
      expect(vc1 <=> vc2).to be 1
    end
  end
end
