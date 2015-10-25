require "spec_helper"
require 'stringio'
require "odm"

class MyClass < Item
end

describe Odm do
  describe "#parse" do
    context "simple input" do
      before(:each) do
        @text = <<'HERE'
MyClass:
  attr1 = 15
  attr2 = "string"
  attr3 = "bananas \
foster"
  attr4 = "two\nlines"
HERE
        @input = StringIO.new(@text)
        @db = Array.new
        def @db.add(a)
          self.push(a)
        end

        @odm = Odm.new(@input, @db)
      end

      it "parses the input" do
        expect { @odm.parse }.not_to raise_error
      end
      
      it "saves all the raw lines" do
        @odm.parse
        expect(@db[0].to_text).to eq(@text)
      end
      
      it "adds the new object to the db" do
        @odm.parse
        expect(@db.length).to eq(1)
      end
      
      it "creates a new object of the same class as the stanza type" do
        @odm.parse
        expect(@db[0].class).to eq(Myclass)
      end
      
      it "parses integer attributes" do
        @odm.parse
        expect(@db[0]["attr1"]).to eq(15)
      end
      
      it "parses string attributes" do
        @odm.parse
        expect(@db[0]["attr2"]).to eq("string")
      end
      
      it "joins continuation lines" do
        @odm.parse
        expect(@db[0]["attr3"]).to eq("bananas foster")
      end
      
      it "changes \\n into newlines" do
        @odm.parse
        expect(@db[0]["attr4"]).to eq("two\nlines")
      end
    end
  end
end
