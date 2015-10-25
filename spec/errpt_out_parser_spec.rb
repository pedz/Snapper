require "spec_helper"
require "errpt_out_parser"
require "db"

describe ErrptOutParser do
  describe "#parse" do
    it "reads in TEST_ERROR_OUT" do
      db = Db.new
      io = File.open(TEST_ERROR_OUT, mode: "r", encoding: "ISO-8859-1")
      ErrptOutParser.new(io, db).parse
      a = db["Errpt"]
      expect(a.length).to eq(821)
      expect(a[0]["Date/Time"]).to eq("Wed Jul 17 05:31:31 2013")
      expect(a[-1]["Sequence Number"]).to eq("6481")
    end
  end
end
