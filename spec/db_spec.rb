require "spec_helper"
require "db"

describe Db do
  it { is_expected.to respond_to(:create_item) }
  it { is_expected.to respond_to(:[]) }
  
  describe "#create_item" do
    it "accepts an item" do
      db = Db.new
      expect{ db.create_item("something") }.not_to raise_error
    end

    it "starts out empty" do
      db = Db.new
      expect(db.empty?).to be true
    end

    it "creates a class if necessary" do
      db = Db.new
      db.create_item("something")
      expect(Something).to be_a(Class)
    end

    it "adds the optional text if given" do
      db = Db.new
      db.create_item("something", "optional text")
      expect(db["Something"].to_text).to eq("optional text")
    end

    it "creates and array if more than one of the same type is added" do
      db = Db.new
      item1 = db.create_item("something")
      item2 = db.create_item("something")
      expect(db["Something"].length).to equal 2
      expect(db["Something"][0]).to eq(item1)
    end
  end

  it "supports marshaling" do
    db = Db.new
    item = db.create_item("foo")
    item['dog'] = "woof"
    new_db = Marshal.load(Marshal.dump(db))
    expect(new_db.foo.dog).to eq(item.dog)
  end
end
