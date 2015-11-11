require "spec_helper"
require "print_list"

describe PrintList do
  subject { PrintList.new }

  it "should have an add method" do
    expect(subject.respond_to?(:add)).to eq(true)
  end

  describe "#add" do
    it "should have an arity of 2" do
      expect(subject.method(:add).arity).to eq(2)
    end

    it "should take an item and a priority" do
      expect { subject.add([ "sample"], 4) }.not_to raise_error
    end

    it "should return self" do
      expect(subject.add([ "sample"], 4)).to be(subject)
    end
  end

  it "should have an items method" do
    expect(subject.respond_to?(:items)).to eq(true)
  end

  describe "#items" do
    it "should return the items in the proper order" do
      subject.add("one", 1)
      subject.add("twelve", 12)
      subject.add("five", 5)
      expect(subject.items).to eq([ "one", "five", "twelve" ])
    end
  end
end
