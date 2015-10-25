require "spec_helper"
require "dot_file_parser"
require "stringio"

describe DotFileParser do
  describe "#parse" do
    it "reads in TEST_TCPIP_SNAP" do
      db = double("db")
      expect(db).to receive(:add).exactly(15).times
      io = File.open(TEST_TCPIP_SNAP, mode: "r", encoding: "ISO-8859-1")
      DotFileParser.new(io, db).parse
    end
    
    it "calls the parser for the proper class" do
      db = double("db")
      foo_v = class_double("DotFileParser::Base")
      foo_instance = instance_double("DotFileParser::Base")
      body = <<EOF
This is some text
blah blah blah
EOF
      expect(foo_v).to receive(:new).with(body, db).and_return(foo_instance)
      expect(foo_instance).to receive(:parse).with(no_args)
      Foo_v = foo_v
      text = <<EOF + body

.....
..... Foo -v
.....

EOF
      expect(db).to receive(:add).exactly(1).times
      DotFileParser.new(StringIO.new(text), db).parse
    end
  end
end
