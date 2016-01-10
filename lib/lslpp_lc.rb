require_relative "lslpp"

# Parses the <tt>lslpp -lc</tt> output found in general.snap.
#
# This is not a subclass of Item because the keys will collide so it
# is just a simple hash with a text field.  The keys are the values of
# Fileset found in the output.  The values are a hash with the keys
# found on the first line.  e.g.
#
#   Fileset:Level:PTF Id:State:Type:Description:EFIX Locked
#
# Path is added.  And a field called vrmf is added which is the Level
# split at the dots and then run through printf of
# %02d.%02d.%04d.%04d.  This gives an easy way to compare vrmf
# fields.
class LslppLc < Hash
  def initialize(text = "", hash = {}, orig_key = {}, db)
    @text = text
    @db = db
  end

  def to_text
    @text
  end

  def parse
    field_names = []
    @text.each_line do |line|
      if line[0] == "#"
        field_names = line.downcase.chomp[1..-1].split(':')
        field_names.unshift("path") unless field_names[0] == "path"
        next
      end
      fail "Field names not set yet" if field_names.empty?
      fields = line.chomp.split(':')
      h = {}
      field_names.each_index do |index|
        h[field_names[index]] = fields[index]
      end
      lslpp = Lslpp.new(h)
      fileset = lslpp.fileset
      if self[fileset].nil? || self[fileset].vrmf  < lslpp.vrmf
        self[fileset] = lslpp
      end
    end
    self
  end
end
