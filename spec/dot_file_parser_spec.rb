require "spec_helper"
require "dot_file_parser"
require "stringio"

describe DotFileParser do
  describe ".parse" do
    it "has an arity of 2" do 
      expect(DotFileParser.method(:parse).arity).to eq(2)
    end

    it "reads in TEST_TCPIP_SNAP" do
      db = double("db")
      expect(db).to receive(:add).exactly(15).times
      io = File.open(TEST_TCPIP_SNAP, mode: "r", encoding: "ISO-8859-1")
      DotFileParser.parse(io, db)
    end
    
    it "calls the parser for the proper class" do
      foo_v = double("foo_v")
      body = <<EOF
This is some text
blah blah blah
EOF
      expect(foo_v).to receive(:new).with(body)
      Foo_v = foo_v
      text = <<EOF + body

.....
..... Foo -v
.....

EOF
      db = double("db")
      expect(db).to receive(:add).exactly(1).times
      DotFileParser.parse(StringIO.new(text), db)
    end
    
    # it "should read in TEST_NETATAT_V" do
    #   db = Db.new
    #   io = IO.popen("bzcat #{TEST_NETSTAT_V}", "r:ISO-8859-1")
    #   DotFileParser.parse(io, db)
    # end
  end
end
