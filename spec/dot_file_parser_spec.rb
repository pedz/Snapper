require "spec_helper"
require "dot_file_parser"
require "stringio"
require "db"

describe DotFileParser do
  describe "#parse" do
    it "reads in TEST_TCPIP_SNAP" do
      item = double("item")
      db = double("db")
      expect(db).to receive(:create_item).exactly(15).times.and_return(item)
      expect(db).to receive(:date_time=).once
      expect(item).to receive(:parse).exactly(15).times
      path = Pathname.new(TEST_TCPIP_SNAP)
      io = path.open(mode: "r", encoding: "ISO-8859-1")
      DotFileParser.new(io, db, path).parse
    end
    
    it "calls the parser for the proper class" do
      item = double("item")
      db = double("db")
      body = <<EOF
This is some text
blah blah blah
EOF
      name = "Foo -v"
      text = <<EOF + body

.....
..... #{name}
.....

EOF
      expect(db).to receive(:create_item).once.with(name, body).and_return(item)
      expect(item).to receive(:parse).once
      DotFileParser.new(StringIO.new(text), db).parse
    end
  end
end
