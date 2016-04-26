require "spec_helper"
require "netstat_v"
require "entstat_generic"

describe NetstatV do
  describe "#parse" do
    before(:each) do
      @db = double("db")
    end
    
    it "rejects random text" do 
      text = "Some text"
      expect{ NetstatV.new(text, @db).parse }.to raise_error(RuntimeError, "No device boundaries found")
    end
    
    it "rejects text without Device type:" do 
      text = <<EOF
ETHERNET STATISTICS (ent1) :
blah blah blah
EOF
      expect{ NetstatV.new(text, @db).parse }.to raise_error(RuntimeError, "'Device Type:' string not found")
    end
    
    it "uses the generic netstat -v parser for an unknown device" do 
      text = <<EOF
ETHERNET STATISTICS (ent1) :
Device Type: blah blah blah
Hardware Address: e4:1f:13:fd:29:75
EOF
      expect(NetstatV.new(text, @db).parse["ent1"].class).to eq(EntstatGeneric)
    end

    it "calls the adapter specific parser and returns its result" do
      ent_name = "ent1"
      adapter_type = "Happy Adapter"
      adapter_specific_text = <<EOF
Device Type: #{adapter_type}
blah blah adapter blah
blee blee blee hambugers are good
EOF
      # The chomp is because we want only one new line or the test fails
      text = <<EOF
ETHERNET STATISTICS (#{ent_name}) :
#{adapter_specific_text.chomp}
EOF
      NetstatV::Parsers.instance.add(Item, adapter_type)
      expect(NetstatV.new(text, @db).parse.to_text).to eq(text)
    end
  end

  it "has a Parsers nested class" do
    expect { NetstatV::Parsers }.not_to raise_error
  end
  
  describe "::Parsers" do
    it "is a singleton" do
      expect { NetstatV::Parsers.instance }.not_to raise_error
    end

    describe "#add" do
      it "has an arity of 2" do
        expect(NetstatV::Parsers.instance.method(:add).arity).to eq(2)
      end

      it "the add method adds an object that the find method finds" do
        s = "specific string"
        NetstatV::Parsers.instance.add(42, s)
        klass = NetstatV::Parsers.instance.find(s)
        expect(klass).to eq(42)
      end
    end
    
    describe "#find" do
      it "has an arity of 1" do
        expect(NetstatV::Parsers.instance.method(:find).arity).to eq(1)
      end
    end
  end
end
