require "spec_helper"
require "seas"
require_relative "factories/snap1"

describe Seas do
  # describe ".process_snap" do
  #   it "should be happy" do
  #     Seas.process_snap(fake_batch(batch1))
  #   end
  # end

  describe ".process_batch", :create_batch_dsl do
    context "testing the mocks" do
      it "accepts batch with no SEAs" do
        batch = Batch.new([ start_new_cec ])
        expect_no_alerts(batch)
        Seas.process_batch(batch)
      end

      it "accepts batch with one SEA with control channel" do
        snap = start_new_cec
        virt = new_vea({ allowed: "None" })
        ctl = new_vea
        add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        batch = Batch.new([ snap ])
        expect_no_alerts(batch)
        Seas.process_batch(batch)
      end

      it "accepts batch with one SEA using discovery protocol" do
        snap = start_new_cec
        virt = new_vea({ allowed: "None", discovery: true })
        add_sea({ virt_adapters: [ virt ] })
        batch = Batch.new([ snap ])
        expect_no_alerts(batch)
        Seas.process_batch(batch)
      end
    end

    context "when using discovery protocol" do
      it "alerts when no control buffers on PVID adapter" do
        snap = start_new_cec
        virt = new_vea({ allowed: "None", discovery: false })
        sea = add_sea({ virt_adapters: [ virt ] })
        batch = Batch.new([ snap ])
        expect(snap).to receive(:add_alert).
                         once.
                         with("#{virt.name} on #{sea.name} should have \"Control\" buffer type and it does not")
        Seas.process_batch(batch)
      end
    end

    context "individual SEA" do
      it "alerts if multiple VEAs using same PVID" do
        snap = start_new_cec
        pvid = 5
        virt = new_vea({ allowed: "None", pvid: pvid })
        ctl = new_vea({ pvid: pvid})
        add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        batch = Batch.new([ snap ])
        expect(snap).to receive(:add_alert).
                         once.
                         with("#{ctl.name} and #{virt.name} both use VLAN #{pvid}")
        Seas.process_batch(batch)
      end

      it "alerts if PVID also allowed" do
        snap = start_new_cec
        pvid = 5
        dup = 7
        allowed = [ 6, dup, 8 ]
        virt = new_vea({ allowed: allowed, pvid: pvid })
        ctl = new_vea({ pvid: dup })
        add_sea({ virt_adapters: [ virt ], ctl_chan: ctl })
        batch = Batch.new([ snap ])
        expect(snap).to receive(:add_alert).
                         once.
                         with("#{ctl.name} and #{virt.name} both use VLAN #{dup}")
        Seas.process_batch(batch)
      end

      xit "alert if any virt_adapters not in trunk mode" do
        
      end

      xit "alert if ctl_chan in trunk mode" do
        
      end
    end

    # context "multiple snaps for the same LPAR" do
    #   xit "alerts mismatched allowed vlans" do

    #   end

    #   xit "alerts mismatched VEAs" do

    #   end
    # end

    # context "snaps from two LPARs" do
    #   xit " alerts if control PVID mismatch" do

    #   end

    #   xit " alerts if control virtual switch mismatch" do

    #   end

    #   xit " alerts mismatched allowed vlans" do

    #   end

    #   xit " alerts mismatched VEAs" do

    #   end
    # end

    # context "snaps from more than two LPARs" do
    #   xit "alerts when more than two SEAs on same control PVID" do

    #   end
    # end
  end
end
