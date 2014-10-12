require "spec_helper"
require "db"

describe Db do
  context "#add" do
    it "accepts an item" do
      expect{ subject.add("something") }.not_to raise_error
    end
  end
  
  context "#table" do
    it "retrives a table for a class of items" do
      expect{ subject.table(String) }.not_to raise_error
    end
    
    context "before adding items" do
      it "returns an empty table" do
        table = subject.table(String)
        expect(table).to be_empty
      end
    end
    
    context "after adding items" do
      it "returns a table with items" do
        subject.add("string")
        subject.add("string")
        subject.add("other")
        table = subject.table(String)
        expect(table.length).to equal 3
        expect(table).to include("string")
        expect(table).to include("other")
      end
    end
  end
end
