require "spec_helper"
require "item"

describe Item do
  subject { Item.new("", Hash.new) }

  describe "#[]=" do

    before { subject["hI"] = 12 }

    it "should set the key in the hash" do
      expect(subject["hI"]).to eq(12)
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
      expect{ subject["HI"] = 14 }.to raise_error("Collision of new key \"HI\" with previous key \"hI\"")
    end

    it "should remember the original key" do
      expect(subject.orig_key[:hi]).to eq("hI")
    end

    it "should allow multiple assignments with the same key" do
      expect{ subject["hI"] = 99 }.not_to raise_error
      expect(subject.hi).to eq(99)
    end

    it "should allow multiple assignments to any key" do
      expect{ subject["Dog"] = 42 }.not_to raise_error
      expect{ subject["Dog"] = 99 }.not_to raise_error
      expect(subject.dog).to eq(99)
    end

    it "should allow modification via the method name" do
      expect{ subject[:hi] = 99 }.not_to raise_error
    end
  end

  describe "#select" do
    it "should return an Item" do
      subject["key1"] = 12
      subject["key2"] = 15
      result = subject.select do |key, value|
        value < 15
      end
      expect(result).to be_a(Item)
      expect(result.length).to eq(1)
    end
  end
end
