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
  describe ".parse" do
    it "has an arity of 2" do 
      expect(Odm.method(:parse).arity).to eq(2)
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

      it "parses the input" do
        expect { Odm.parse(@input, @db) }.not_to raise_error
      end
      
      it "adds the new object to the db" do
        Odm.parse(@input, @db)
        expect(@db.length).to eq(1)
      end
      
      it "creates a new object of the same class as the stanza type" do
        Odm.parse(@input, @db)
        expect(@db[0].class).to eq(MyClass)
      end
      
      it "parses integer attributes" do
        Odm.parse(@input, @db)
        expect(@db[0].hash["attr1"]).to eq(15)
      end
      
      it "parses string attributes" do
        Odm.parse(@input, @db)
        expect(@db[0].hash["attr2"]).to eq("string")
      end
      
      it "joins continuation lines" do
        Odm.parse(@input, @db)
        expect(@db[0].hash["attr3"]).to eq("bananas foster")
      end
      
      it "changes \\n into newlines" do
        Odm.parse(@input, @db)
        expect(@db[0].hash["attr4"]).to eq("two\nlines")
      end
    end
  end
end
