require "spec_helper"
require "ethchans"

describe Ethchans, :batch_dsl do
  describe ".process_snap" do
    context "testing the mocks" do
      it "accepts snap with no ether channels" do
        snap = start_new_snap
        expect(snap).not_to receive(:add_alert)
        Ethchans.process_snap(snap)
      end
    end
  end
end
