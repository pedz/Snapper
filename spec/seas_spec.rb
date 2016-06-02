require "spec_helper"
require "seas"

describe Seas, :batch_dsl do
  describe ".process_snap" do
    context "testing the mocks" do
      it "accepts snap with no SEAs" do
        snap = start_new_snap
        expect(snap).not_to receive(:add_alert)
        expect(Seas).not_to receive(:caught_rescue)
        Seas.process_snap(snap, {})
      end

      it "accepts snap with one SEA with control channel" do
        snap = start_new_snap
        sea = add_sea(ctl_chan: new_vea)
        expect(sea[:ctl_chan]).to_not be_nil
        t = sea[:pvid_adapter].entstat
        expect(t).to_not be_nil
        [ "Receive Information", "Receive Buffers", "Control" ].each do |attr|
          t = t[attr] if t
        end
        expect(t).to be_nil
        expect(snap).not_to receive(:add_alert)
        expect(Seas).not_to receive(:caught_rescue)
        Seas.process_snap(snap, {})
      end

      it "accepts snap with one SEA using discovery protocol" do
        snap = start_new_snap
        add_sea
        expect(snap).not_to receive(:add_alert)
        expect(Seas).not_to receive(:caught_rescue)
        Seas.process_snap(snap, {})
      end
    end

    context "misconfigured SEA" do
      it "alerts when pvid attribute of the SEA mismatches the Port VLAN ID of the pvid_adapter" do
        snap = start_new_snap
        vea_pvid = 99
        sea_pvid = vea_pvid + 1
        virt = new_vea({ allowed: "None", discovery: true, pvid: vea_pvid })
        sea = add_sea({ virt_adapters: [ virt ], pvid: sea_pvid })
        expect(Seas).not_to receive(:caught_rescue)
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.pvid_mismatch(sea.name, sea_pvid, virt.name, vea_pvid))
        Seas.process_snap(snap, {})
      end
      
      it "alerts when adapter_reset is set to \"yes\"" do
        snap = start_new_snap
        sea = add_sea({ adapter_reset: "yes" })
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.reset_adapter_yes(sea.name, "yes"))
        expect(Seas).not_to receive(:caught_rescue)
        Seas.process_snap(snap, {})
      end
      
      it "alert if any virt_adapters not in trunk mode" do
        snap = start_new_snap
        virt = new_vea
        ctl = new_vea
        sea = add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.not_trunk(sea.name, virt.name))
        expect(Seas).not_to receive(:caught_rescue)
        Seas.process_snap(snap, {})
      end
      
      it "alert if ctl_chan in trunk mode" do
        snap = start_new_snap
        virt = new_vea({ allowed: "None" })
        ctl = new_vea({ allowed: "None" })
        sea = add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.is_trunk(sea.name, ctl.name))
        expect(Seas).not_to receive(:caught_rescue)
        Seas.process_snap(snap, {})
      end
    end

    context "when using discovery protocol" do
      it "alerts when no control buffers on PVID adapter" do
        snap = start_new_snap
        sea = add_sea(discovery: false)
        virt = sea[:pvid_adapter]
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.discovery_vea(sea.name, virt.name))
        Seas.process_snap(snap, {})
      end
    end

    context "validate SEA state" do
      it "alerts when state is PRIMARY but bridge mode is not All" do
        snap = start_new_snap
        sea = add_sea()
        virt = sea[:pvid_adapter]
        sea.entstat['State'] = "PRIMARY"
        sea.entstat['Bridge Mode'] = "None"
        virt.entstat['Active'] = "False"
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.bmode_not_correct(sea.name, "All", "None"))
        Seas.process_snap(snap, {})
      end

      it "alerts when SEA Bridge Mode All and VEA is not active" do
        snap = start_new_snap
        sea = add_sea()
        virt = sea[:pvid_adapter]
        sea.entstat['State'] = "PRIMARY"
        sea.entstat['Bridge Mode'] = "All"
        virt.entstat['Active'] = "False"
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.vea_not_active(sea.name, virt.name))
        Seas.process_snap(snap, {})
      end

      it "alerts when SEA Bridge Mode None and VEA is active" do
        snap = start_new_snap
        sea = add_sea()
        virt = sea[:pvid_adapter]
        sea.entstat['State'] = "BACKUP"
        sea.entstat['Bridge Mode'] = "None"
        virt.entstat['Active'] = "True"
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.vea_is_active(sea.name, virt.name))
        Seas.process_snap(snap, {})
      end

      it "alerts when SEA Bridge Mode Partial and VEA not in VID Shared is active" do
        snap = start_new_snap
        pvid1 = 99
        pvid2 = 100
        vea1 = new_vea({ pvid: pvid1, allowed: [ 101 ] })
        vea2 = new_vea({ pvid: pvid2, allowed: [ 102 ] })
        ctl = new_vea
        sea = add_sea({ virt_adapters: [ vea1, vea2 ], ctl_chan: ctl })
        sea.entstat['State'] = "PRIMARY_SH"
        sea.entstat['Bridge Mode'] = "Partial"
        vea1.entstat['Active'] = "True"
        vea2.entstat['Active'] = "True"
        sea.entstat['VID Shared'] = "99 101"
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.vea_is_active(sea.name, vea2.name))
        Seas.process_snap(snap, {})
      end

      it "alerts when SEA Bridge Mode Partial and VEA in VID Shared is not active" do
        snap = start_new_snap
        pvid1 = 99
        pvid2 = 100
        vea1 = new_vea({ pvid: pvid1, allowed: [ 101 ] })
        vea2 = new_vea({ pvid: pvid2, allowed: [ 102 ] })
        ctl = new_vea
        sea = add_sea({ virt_adapters: [ vea1, vea2 ], ctl_chan: ctl })
        sea.entstat['State'] = "PRIMARY_SH"
        sea.entstat['Bridge Mode'] = "Partial"
        vea1.entstat['Active'] = "False"
        vea2.entstat['Active'] = "False"
        sea.entstat['VID Shared'] = "99 101"
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.vea_not_active(sea.name, vea1.name))
        Seas.process_snap(snap, {})
      end
    end
  end

  describe ".process_batch" do
    context "testing the mocks" do
      it "accepts batch with no SEAs" do
        batch = Batch.new([ start_new_cec ])
        expect_no_alerts(batch)
        Seas.process_batch(batch, {})
      end

      it "accepts batch with one SEA with control channel" do
        snap = start_new_cec
        virt = new_vea({ allowed: "None" })
        ctl = new_vea
        add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        batch = Batch.new([ snap ])
        expect_no_alerts(batch)
        Seas.process_batch(batch, {})
      end

      it "accepts batch with one SEA using discovery protocol" do
        snap = start_new_cec
        virt = new_vea({ discovery: true })
        add_sea({ virt_adapters: [ virt ] })
        batch = Batch.new([ snap ])
        expect_no_alerts(batch)
        Seas.process_batch(batch, {})
      end
    end

    context "individual SEA" do
      it "alerts if multiple VEAs using same PVID" do
        snap = start_new_cec
        pvid = 5
        vswitch = "vswitch1"
        virt = new_vea({ pvid: pvid, vswitch: vswitch })
        ctl = new_vea({ pvid: pvid, vswitch: vswitch })
        add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        batch = Batch.new([ snap ])
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.vid_conflict(ctl.name, virt.name, pvid, vswitch))
        Seas.process_batch(batch, {})
      end

      it "alerts if PVID also allowed" do
        snap = start_new_cec
        pvid = 5
        dup = 7
        allowed = [ 6, dup, 8 ]
        vswitch = "vswitch1"
        virt = new_vea({ allowed: allowed, pvid: pvid, vswitch: vswitch })
        ctl = new_vea({ pvid: dup, vswitch: vswitch })
        add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        batch = Batch.new([ snap ])
        expect(snap).to receive(:add_alert).
                         once.
                         with(Seas::Alerts.vid_conflict(ctl.name, virt.name, dup, vswitch))
        Seas.process_batch(batch, {})
      end
    end

    context "multiple snaps for the same LPAR" do
      it "alerts mismatched allowed vlans" do
        pvid = 99
        vswitch = "vs1"
        snap1 = start_new_cec
        vea1 = new_vea({ pvid: pvid, vswitch: vswitch, discovery: true, allowed: [ 1, 2, 3 ] })
        sea1 = add_sea( virt_adapters: [ vea1 ])

        snap2 = start_new_snap
        vea2 = new_vea({ pvid: pvid, vswitch: vswitch, discovery: true, allowed: [ 1, 2, 3, 4 ] })
        sea2 = add_sea( virt_adapters: [ vea2 ])

        batch = Batch.new([ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.sea_changed(sea1.name, vswitch, pvid))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.sea_changed(sea2.name, vswitch, pvid))
        Seas.process_batch(batch, {})
      end

      it "alerts mismatched VEAs" do
        pvid = 99
        vswitch = "vs1"
        snap1 = start_new_cec
        vea1 = new_vea({ pvid: pvid, vswitch: vswitch, discovery: true, allowed: [ 1, 2, 3 ] })
        sea1 = add_sea( virt_adapters: [ vea1 ])

        snap2 = start_new_snap
        vea2 = new_vea({ pvid: pvid, vswitch: vswitch, discovery: true, allowed: [ 1, 2, 3 ] })
        veax = new_vea({ pvid: pvid + 1, vswitch: vswitch, allowed: "None" })
        sea2 = add_sea( virt_adapters: [ vea2, veax ])

        batch = Batch.new( [ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.sea_changed(sea1.name, vswitch, pvid))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.sea_changed(sea2.name, vswitch, pvid))
        Seas.process_batch(batch, {})
      end
    end

    context "snaps from two LPARs" do
      it " alerts if control PVID mismatch" do
        snap1 = start_new_cec
        pvid1 = 99
        sea1 = add_sea(pvid: pvid1)

        snap2 = start_new_lpar
        pvid2 = 100
        sea2 = add_sea(pvid: pvid2)

        batch = Batch.new([ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          once.
                          with(Seas::Alerts.unmatched_sea(sea1.name))
        expect(snap2).to receive(:add_alert).
                          once.
                          with(Seas::Alerts.unmatched_sea(sea2.name))
        Seas.process_batch(batch, {})
      end

      it " alerts if control virtual switch mismatch" do
        pvid = 99
        snap1 = start_new_cec
        sea1 = add_sea(pvid: pvid, vswitch: "vs1")

        snap2 = start_new_lpar
        sea2 = add_sea(pvid: pvid, vswitch: "vs2")

        batch = Batch.new([ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          once.
                          with(Seas::Alerts.unmatched_sea(sea1.name))
        expect(snap2).to receive(:add_alert).
                          once.
                          with(Seas::Alerts.unmatched_sea(sea2.name))
        Seas.process_batch(batch, {})
      end

      it " alerts mismatched allowed vlans" do
        pvid = 1
        allowed1 = [ 2, 3, 4 ]
        snap1 = start_new_cec
        sea1 = add_sea({ pvid: pvid, allowed: allowed1 })
        vea_conf1 = Seas::VeaConfig.new(sea1[:pvid_adapter])
        
        allowed2 = [ 2, 3, 5 ]
        snap2 = start_new_lpar
        sea2 = add_sea({ pvid: pvid, allowed: allowed2 })
        vea_conf2 = Seas::VeaConfig.new(sea2[:pvid_adapter])

        batch = Batch.new([ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.vlan_missing(sea1.name, [ 5 ], vea_conf1))
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.vlan_added(sea1.name, [ 4 ], vea_conf1))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.vlan_added(sea2.name, [ 5 ], vea_conf2))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.vlan_missing(sea2.name, [ 4 ], vea_conf2))
        Seas.process_batch(batch, {})
      end

      it " alerts mismatched VEAs [case 1]" do
        ctl_pvid = 99
        vea_pvid = 100
        extra_pvid = 101
        snap1 = start_new_cec
        vea1_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        ctl1 = new_vea({ pvid: ctl_pvid })
        sea1 = add_sea({ ctl_chan: ctl1, virt_adapters: [ vea1_1 ]})

        snap2 = start_new_lpar
        vea2_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        vea2_2 = new_vea({ pvid: extra_pvid, allowed: "None" })
        vea_conf2_2 = Seas::VeaConfig.new(vea2_2)
        ctl2 = new_vea({ pvid: ctl_pvid })
        sea2 = add_sea({ ctl_chan: ctl2, virt_adapters: [ vea2_1, vea2_2 ]})

        batch = Batch.new( [ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.vea_missing(sea1.name, vea_conf2_2))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.vea_added(sea2.name, vea_conf2_2))
        Seas.process_batch(batch, {})
      end

      it " alerts mismatched VEAs [case 2]" do
        ctl_pvid = 99
        vea_pvid = 100
        extra_pvid = 101
        snap1 = start_new_cec
        vea1_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        vea1_2 = new_vea({ pvid: extra_pvid, allowed: "None" })
        ctl1 = new_vea({ pvid: ctl_pvid })
        sea1 = add_sea({ ctl_chan: ctl1, virt_adapters: [ vea1_1, vea1_2 ]})
        vea_conf1_2 = Seas::VeaConfig.new(vea1_2)

        snap2 = start_new_lpar
        vea2_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        ctl2 = new_vea({ pvid: ctl_pvid })
        sea2 = add_sea({ ctl_chan: ctl2, virt_adapters: [ vea2_1 ]})

        batch = Batch.new( [ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.vea_added(sea1.name, vea_conf1_2))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.vea_missing(sea2.name, vea_conf1_2))
        Seas.process_batch(batch, {})
      end

      it " alerts mismatched VEAs [case 3]" do
        ctl_pvid = 99
        vea_pvid = 101
        extra_pvid = 100
        snap1 = start_new_cec
        vea1_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        vea1_2 = new_vea({ pvid: extra_pvid, allowed: "None" })
        ctl1 = new_vea({ pvid: ctl_pvid })
        sea1 = add_sea({ ctl_chan: ctl1, virt_adapters: [ vea1_1, vea1_2 ]})
        vea_conf1_2 = Seas::VeaConfig.new(vea1_2)

        snap2 = start_new_lpar
        vea2_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        ctl2 = new_vea({ pvid: ctl_pvid })
        sea2 = add_sea({ ctl_chan: ctl2, virt_adapters: [ vea2_1 ]})

        batch = Batch.new( [ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.vea_added(sea1.name, vea_conf1_2))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.vea_missing(sea2.name, vea_conf1_2))
        Seas.process_batch(batch, {})
      end

      it " alerts mismatched VEAs [case 4]" do
        ctl_pvid = 99
        vea_pvid = 101
        extra_pvid = 100
        snap1 = start_new_cec
        vea1_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        ctl1 = new_vea({ pvid: ctl_pvid })
        sea1 = add_sea({ ctl_chan: ctl1, virt_adapters: [ vea1_1 ]})

        snap2 = start_new_lpar
        vea2_1 = new_vea({ pvid: vea_pvid, allowed: "None" })
        vea2_2 = new_vea({ pvid: extra_pvid, allowed: "None" })
        vea_conf2_2 = Seas::VeaConfig.new(vea2_2)
        ctl2 = new_vea({ pvid: ctl_pvid })
        sea2 = add_sea({ ctl_chan: ctl2, virt_adapters: [ vea2_1, vea2_2 ]})

        batch = Batch.new( [ snap1, snap2 ])
        expect(snap1).to receive(:add_alert).
                          with(Seas::Alerts.vea_missing(sea1.name, vea_conf2_2))
        expect(snap2).to receive(:add_alert).
                          with(Seas::Alerts.vea_added(sea2.name, vea_conf2_2))
        Seas.process_batch(batch, {})
      end
    end

    context "snaps from more than two LPARs" do
      it "alerts when more than two SEAs on same control PVID" do
        pvid = 99
        vswitch = "vs1"

        snap1 = start_new_cec
        sea1 = add_sea(pvid: pvid, vswitch: vswitch)

        snap2 = start_new_lpar
        sea2 = add_sea(pvid: pvid, vswitch: vswitch)

        snap3 = start_new_lpar
        sea3 = add_sea(pvid: pvid, vswitch: vswitch)

        expect(snap1).to receive(:add_alert)
        expect(snap2).to receive(:add_alert)
        expect(snap3).to receive(:add_alert)

        batch = Batch.new( [ snap1, snap2, snap3 ])
        Seas.process_batch(batch, {})
      end
    end
  end
end
