require "spec_helper"
require "netstat_in"

describe Item do
  subject { Item.new("", Hash.new) }

  describe "#[]=" do

    before { subject["hi"] = 12 }

    it "should set the key in the hash" do
      expect(subject["hi"]).to eq(12)
    end

    it "should create a method for the key" do
      expect(subject.respond_to?(:hi)).to eq(true)
    end

    it "should create a method that returns the value" do
      expect(subject.hi).to eq(12)
    end

    it "should alter the key to be a valid method name" do
      subject["this IS -a test"] = 14
      expect(subject.this_is__a_test).to eq(14)
    end

    it "should fail when collisions on keys occurs" do
      expect{ subject["HI"] = 14 }.to raise_error("Collision with HI to hi")
    end

    it "should allow multiple assignments with the same key" do
      expect{ subject["hi"] = 99 }.not_to raise_error
      expect(subject.hi).to eq(99)
    end

    it "should allow multiple assignments to any key" do
      expect{ subject["Dog"] = 42 }.not_to raise_error
      expect{ subject["Dog"] = 99 }.not_to raise_error
      expect(subject.dog).to eq(99)
    end
  end
end
