require_relative 'devices'
require_relative 'snapper'

# Scattered about there are <tt>lsattr -El foo</tt> output in places
# like +general.snap+, +async.snap+, and perfpmr's +config.sum+.
# These do not match a common class at parse time nor can a match be
# made based upon the device's type because the device's type is not
# know at that point in time.
#
# A pass is made to alter these to be of class Lsattr or one of its
# subclasses which will be based on the basename of the ddins.
# e.g. the one for the SEA will be called LsattrSeadd.  If a
# specialized class does not exist, an item of Lsattr class will be
# created.
#
# A container of the the lsattr entries is made in the db called
# +lsattrs+ and has each lsattr under the device's logical name (much
# like +devices+.
class Lsattr < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # @return [Regexp] Pattern that matches the original class like
  #   lsattr_elent0 where ent0 is the logical name of the device.
  NAME_REGEXP = /\Alsattr_el(.*)\z/

  # Scans the lines capture by the lsattr_elfoo class and tries to
  # determine the attribute name, value, description, and alterable
  # values.  Creates an lsattrs entry in the db which has keys of the
  # logical name for the device and an item which has the fields of
  # +:attr+, +:value+, +:desc+, and +:alter+.
  # @param snap [Snap] the snap to scan.
  # @raise [RuntimeError] if the parse failed.
  def self.process_snap(snap)
    db = snap.db
    lsattrs = db.create_item("lsattrs")
    devices = db.devices
    db.each_pair do |key, orig_item|
      next unless (md = NAME_REGEXP.match(key))
      orig_item = orig_item.first if orig_item.is_a?(Array)
      lines = orig_item.to_text.split("\n")
      next if lines.empty?

      logical_name = md[1]
      if (device = devices[logical_name]) &&
         (cu_dv = device['cu_dv']) &&
         (driver = cu_dv.ddins.sub(/.*\//, ''))
        class_name = "lsattr_#{driver}"
      else
        class_name = "lsattr"
      end
      klass = get_class(class_name, Lsattr)
      new_item = klass.new(orig_item.to_text, db)
      lines = new_item.to_text.split("\n")

      # There are four columns of data each with a left (first
      # non-blank) column and a right (last non-blank column) side.
      # These columns will be numbered 0 through 3.
      left = []
      right = []
      current_column = 0
      (0 .. 3).each do |column|
        # First increment column until at least one line has a
        # non-blank character in that column
        flag = true
        loop do
          flag = false
          lines.each do |line|
            fail "Could not parse lsattr output for #{key}" if (line.length <= current_column)
            if line[current_column] != ' '
              flag = true
              break
            end
          end
          break if flag
          current_column += 1 
        end
        left[column] = current_column
        current_column += 1

        # Now find the right side (end) of the column by scanning all
        # rows until all of them have a blank in that column or we
        # fall off the end of the line
        flag = true
        while flag
          flag = false
          lines.each do |line|
            if (line.length > current_column) && (line[current_column] != ' ')
              flag = true
              break
            end
          end
          current_column += 1 if flag
        end
        right[column] = current_column
        current_column += 1
      end
      
      new_item.to_text.each_line do |line|
        attr =  line[left[0] .. right[0]].strip
        value = line[left[1] .. right[1]].strip
        desc  = line[left[2] .. right[2]].strip
        alter = line[left[3] .. right[3]].strip
        if value.empty?
          value = nil
        else
          value = value.to_i if /\A[0-9]+\Z/.match(value)
        end
        target = Item.new("", db)
        target[:value] = value
        target[:desc]  = desc
        target[:alter] = alter
        new_item[attr] = target
      end
      lsattrs[key] = new_item
      devices[logical_name]['lsattr'] = new_item if devices.has_key?(logical_name)
    end
  end
  Snapper.add_snap_processor(self)
end
