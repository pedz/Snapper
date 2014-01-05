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
  attr3 = "bananas \n\
foster"
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
      expect(@db[0].class).to eq(MyClass)
      expect(@db[0].hash["attr1"]).to eq(15)
      expect(@db[0].hash["attr2"]).to eq("string")
      expect(@db[0].hash["attr3"]).to eq("bananas \nfoster")
    end
  end
end
