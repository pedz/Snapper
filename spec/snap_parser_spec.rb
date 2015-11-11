require "spec_helper"
require "snap_parser"
require "db"

describe SnapParser do
  describe '#parse' do 
    it "accepts prune of nil" do
      SnapParser.new(TEST_SNAP, nil, true, []).parse
    end
    
    it "calls parse on the matches" do
      mock_class = double("Klass")
      mock_instance = double("instance")
      expect(mock_class).to receive(:new).exactly(17).times.and_return(mock_instance)
      expect(mock_instance).to receive(:parse).exactly(17).times.with(no_args)
      # This matches the Foo.add in general but not the Foo.vc.add files
      # It is mostly practicing with negative look ahead.
      SnapParser.new(TEST_SNAP, nil, true, { %r{/general/([^.]*\.)(?!vc\.)add\z} => mock_class } ).parse
    end
    
    it "calls parse on the matches with the proper arguments" do
      mock_class = double("Klass")
      mock_instance = double("instance")
      expect(mock_class).to receive(:new) do |io, db|
        expect(io).to be_an(IO) 
        expect(db).to be_an(Db) 
        expect(io.to_path).to be == (TEST_SNAP + '/general/general.snap')
      end.and_return(mock_instance)
      expect(mock_instance).to receive(:parse).with(no_args)
      SnapParser.new(TEST_SNAP, nil, Db.new, { %r{/general.snap\z} => mock_class } ).parse
    end
    
    it "respects the prune argument" do
      # should match XS25/XS25.snap
      mock_class = double("Klass")
      mock_instance = double("instance")
      expect(mock_class).to receive(:new).exactly(1).times.and_return(mock_instance)
      expect(mock_instance).to receive(:parse).exactly(1).times.with(no_args).with(no_args)
      SnapParser.new(TEST_SNAP, %r{#{Regexp.quote(TEST_SNAP.to_s)}/[^X]}, true, { /./ => mock_class }).parse
    end
  end
end
