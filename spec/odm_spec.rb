require "spec_helper"
require 'stringio'
require "db"
require "odm"

class MyClass < Item
end

describe Odm do
  describe "#parse" do
    context "simple input" do
      before(:context) do
        @text = <<'HERE'
MyClass:
  attr1 = 15
  attr2 = "string"
  attr3 = "bananas \
foster"
  attr4 = "two\nlines"
HERE
        @input = StringIO.new(@text)
        @db = Db.new
        @odm = Odm.new(@input, @db)
      end

      it "parses the input" do
        expect { @odm.parse }.not_to raise_error
      end
      
      # Originally we saved the raw text lines and we can go back and
      # do that but it consumed space and time and was never used.
      #
      # it "saves all the raw lines" do
      #   @odm.parse
      #   expect(@db[:my_class].to_text).to eq(@text)
      # end
      
      it "adds the new object to the db" do
        @odm.parse
        expect(@db.length).to eq(1)
      end
      
      it "creates a new object of the same class as the stanza type" do
        @odm.parse
        expect(@db[:my_class].class).to eq(MyClass)
      end
      
      it "parses integer attributes" do
        @odm.parse
        expect(@db[:my_class]["attr1"]).to eq(15)
      end
      
      it "parses string attributes" do
        @odm.parse
        expect(@db[:my_class]["attr2"]).to eq("string")
      end
      
      it "joins continuation lines" do
        @odm.parse
        expect(@db[:my_class]["attr3"]).to eq("bananas foster")
      end
      
      it "changes \\n into newlines" do
        @odm.parse
        expect(@db[:my_class]["attr4"]).to eq("two\nlines")
      end
    end
  end
end
