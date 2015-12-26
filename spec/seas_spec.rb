require "spec_helper"
require "seas"
require_relative "factories/snap1"

describe Seas do
  # describe ".process_snap" do
  #   it "should be happy" do
  #     Seas.process_snap(fake_batch(batch1))
  #   end
  # end

  describe ".process_batch" do
    it "should be happy with valid mock" do
      Seas.process_batch(expect_no_alerts(fake_batch(batch1)))
    end

    context "when using discovery protocol" do
      it "alerts when no control buffers" do
        batch = fake_batch(batch1)
        adjust_batch(batch,
          [
            [ :dir, "/some/path", proc do |snap|
                expect(snap).to receive(:add_alert).
                                 once.
                                 with("ent15 on ent16 should have \"Control\" buffer type and it does not")
              end ],
            [ :name, "ent15", proc do |ent15|
                ent15.entstat.receive_information.receive_buffers.delete(:control)
              end ]
          ])
        Seas.process_batch(batch)
      end
    end
  end
end
