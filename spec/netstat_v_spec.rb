require "spec_helper"
require "netstat_v"
require "netstat_v_generic"

describe Netstat_v do
  it "rejects random text" do 
    text = "Some text"
    expect{ Netstat_v.new(text) }.to raise_error(RuntimeError, "No device boundaries found")
  end

  it "rejects text without Device type:" do 
    text = <<EOF
ETHERNET STATISTICS (ent1) :
blah blah blah
EOF
    expect{ Netstat_v.new(text) }.to raise_error(RuntimeError, "Device name: ent1\n'Device Type:' string not found")
  end

  it "uses the generic netstat -v parser for an unknown device" do 
    text = <<EOF
ETHERNET STATISTICS (ent1) :
Device Type: blah blah blah
Hardware Address: e4:1f:13:fd:29:75
EOF
    expect(Netstat_v.new(text).class).to eq(Netstat_v)
  end

  it "has a Parsers nested class" do
    expect { Netstat_v::Parsers }.not_to raise_error
  end
  
  describe Netstat_v::Parsers do
    it "is a singleton" do
      expect { Netstat_v::Parsers.instance }.not_to raise_error
    end

    describe 'Netstat_v::Parsers.instance' do
      describe "#add" do
        it "has an arity of 2" do
          expect(Netstat_v::Parsers.instance.method(:add).arity).to eq(2)
        end
      end

      describe "#find" do
        it "has an arity of 1" do
          expect(Netstat_v::Parsers.instance.method(:find).arity).to eq(1)
        end
      end

      it "the add method adds an object that the find method finds" do
        s = "specific string"
        Netstat_v::Parsers.instance.add(42, s)
        klass = Netstat_v::Parsers.instance.find(s)
        expect(klass).to eq(42)
      end
    end
  end

  it "calls the adapter specific parser and return its result" do
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
    Netstat_v::Parsers.instance.add(DotFileParser::Base, adapter_type)
    expect(Netstat_v.new(text).to_json).to eq({ ent_name => adapter_specific_text }.to_json)
  end
end
