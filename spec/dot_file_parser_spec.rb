require "spec_helper"
require "dot_file_parser.rb"

describe DotFileParser do
  it "should have a parse method" do
    expect(DotFileParser).to respond_to(:parse)
  end

  it "should read in TEST_TCPIP_SNAP" do
    db = double("db")
    expect(db).to receive(:add).exactly(15).times
    io = File.open(TEST_TCPIP_SNAP, mode: "r", encoding: "ISO-8859-1")
    DotFileParser.parse(io, db)
  end
end
