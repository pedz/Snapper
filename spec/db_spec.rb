require "spec_helper"
require "db"

describe Db do
  it { is_expected.to respond_to(:add) }
  it { is_expected.to respond_to(:table) }
  
  context "#add" do
    it "accepts an item" do
      db = Db.new
      expect{ db.add("something") }.not_to raise_error
    end
  end
  
  context "#table" do
    it "retrives a table for a class of items" do
      db = Db.new
      expect{ db.table(String) }.not_to raise_error
    end
    
    context "before adding items" do
      it "returns an empty table" do
        db = Db.new
        table = db.table(String)
        expect(table).to be_empty
      end
    end
    
    context "after adding items" do
      it "returns a table with items" do
        db = Db.new
        db.add("string")
        db.add("string")
        db.add("other")
        table = db.table(String)
        expect(table.length).to equal 3
        expect(table).to include("string")
        expect(table).to include("other")
      end
    end
  end
end
