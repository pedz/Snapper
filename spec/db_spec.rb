require "spec_helper"
require "db"

describe Db do
  it { is_expected.to respond_to(:add) }
  it { is_expected.to respond_to(:[]) }
  
  context "#add" do
    it "accepts an item" do
      db = Db.new
      expect{ db.add("something") }.not_to raise_error
    end

    it "starts out empty" do
      db = Db.new
      expect(db["String"]).to be nil
    end

    it "adds based upon the class being added" do
      db = Db.new
      db.add("something")
      expect(db["String"]).to eq("something")
    end

    it "creates and array if more than one of the same type is added" do
      db = Db.new
      db.add("something")
      db.add("else")
      expect(db["String"].length).to equal 2
      expect(db["String"][0]).to eq("something")
    end
  end
end
