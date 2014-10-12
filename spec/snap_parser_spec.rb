require "spec_helper"
require "snap_parser"

describe SnapParser do
  describe '.parse' do 
    it "has an arity of 4" do 
      expect(SnapParser.method(:parse).arity).to eq(4)
    end
    
    it "accepts prune of nil" do
      SnapParser.parse(TEST_SNAP, nil, true, [])
    end
    
    it "calls parse on the matches" do
      mock = double("Klass")
      expect(mock).to receive(:parse).exactly(17).times
      # This matches the Foo.add in general but not the Foo.vc.add files
      # It is mostly practicing with negative look ahead.
      SnapParser.parse(TEST_SNAP, nil, true, { %r{/general/([^.]*\.)(?!vc\.)add\z} => mock } )
    end
    
    it "calls parse on the matches with the proper arguments" do
      mock = double("Klass")
      expect(mock).to receive(:parse) do |p, x|
        expect(p).to be_an(IO)
        expect(x).to be(true)
        expect(p.to_path).to be == (TEST_SNAP + '/general/general.snap')
      end
      SnapParser.parse(TEST_SNAP, nil, true, { %r{/general.snap\z} => mock } )
    end
    
    it "respects the prune argument" do
      # should match .desc, .files, .level, and XS25/XS25.snap
      mock = double("Klass")
      expect(mock).to receive(:parse).exactly(4).times
      SnapParser.parse(TEST_SNAP, %r{#{Regexp.quote(TEST_SNAP.to_s)}/[a-z]}, true, { /./ => mock })
    end
  end
end
