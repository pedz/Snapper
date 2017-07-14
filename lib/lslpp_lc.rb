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

  # An enumerator that produces a flat set of values.
  # @param nesting [Array<String>] The starting nesting to use.
  # @return [Array<Array(String, Object)>] An array of two element
  #   items: the first element is the flattened key.  The second
  #   element is value.
  def flat_keys(nesting = [])
    flatten_keys(self, nesting)
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

  private

  # The magic behind flat_keys: a lazy recursive enumerator.
  # @param thing [Item, Array, Hash, other] The entity to return the
  #   flat keys for.
  # @param nesting [Array<String>] The list of keys needed to get to
  #   +thing+.
  # @return (see #flat_keys)
  def flatten_keys(thing, nesting = [])
    Enumerator.new do |yielder|
      if thing.is_a?(Array)
        thing.each_with_index do |value, index|
          flatten_keys(value, nesting.dup.push(index)).each { |h| yielder << h }
        end
      elsif thing.is_a?(Hash)
        thing.each_pair do |key, value|
          flatten_keys(value, nesting.dup.push(key)).each { |h| yielder << h }
        end
      elsif thing.is_a?(Item)
        if thing.keys.empty?
          yielder << [ nesting.join(','), "<not parsed>"]
        else
          thing.each_pair do |key, value|
            flatten_keys(value, nesting.dup.push(thing.orig_key[key])).each { |h| yielder << h }
          end
        end
      else
        yielder << [ nesting.join(','), thing ]
      end
    end.lazy
  end
end
