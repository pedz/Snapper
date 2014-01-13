require "spec_helper"
require 'stringio'
require "odm"

class MyClass
  attr_reader :hash
  
  def initialize(hash)
    @hash = hash
  end
end

describe Odm do
  it "should have a parse method" do
    expect(Odm).to respond_to(:parse)
  end

  context "simple input" do
    before(:each) do
      @input = StringIO.new <<'HERE'
MyClass:
  attr1 = 15
  attr2 = "string"
  attr3 = "bananas \
foster"
  attr4 = "two\nlines"
HERE
      @db = Array.new
      def @db.add(a)
        self.push(a)
      end
    end

    it "should parse the input" do
      expect { Odm.parse(@input, @db) }.not_to raise_error
    end

    it "should add the new object to the db" do
      Odm.parse(@input, @db)
      expect(@db.length).to eq(1)
    end

    it "should create a new object of the same class as the stanza type" do
      Odm.parse(@input, @db)
      expect(@db[0].class).to eq(MyClass)
    end

    it "should parse integer attributes" do
      Odm.parse(@input, @db)
      expect(@db[0].hash["attr1"]).to eq(15)
    end

    it "should parse string attributes" do
      Odm.parse(@input, @db)
      expect(@db[0].hash["attr2"]).to eq("string")
    end

    it "should join continuation lines" do
      Odm.parse(@input, @db)
      expect(@db[0].hash["attr3"]).to eq("bananas foster")
    end

    it "should change \\n into newlines" do
      Odm.parse(@input, @db)
      expect(@db[0].hash["attr4"]).to eq("two\nlines")
    end
  end
end
