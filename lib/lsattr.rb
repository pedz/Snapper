require_relative 'devices'
require_relative 'snapper'

# Scattered about there are lsattr -El foo output in places like
# general.snap, async.snap, and perfpmr's config.sum.  These do not
# match a common class at parse time nor can a match be made based
# upon the device's type because the device's type is not know at that
# point in time.
#
# A pass is made to alter these to be of class Lsattr or one of its
# subclasses which will be based on the basename of the ddins.
# e.g. the one for the SEA will be called LsattrSeadd.  If a
# specialized class does not exist, an item of Lsattr class will be
# created.
#
# A container of the the lsattr entries is made in the db called
# 'lsattrs' and has each lsattr under the device's logical name (much
# like 'devices'
class Lsattr < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # A Regexp pattern that matches the original class like
  # lsattr_elent0 where ent0 is the logical name of the device.
  NAME_REGEXP = /\Alsattr_el(.*)\z/

  # A sample line
  #   arp           on   Address Resolution Protocol (ARP)             True
  # A Regexp pattern that matches a attr : value description True|False
  # The problem with this is it is too simple.  There are attributes
  # that have no value e.g.
  #   alias6             IPv6 Alias including Prefix Length            True
  # The case of the attributes that have no value, the parse will be
  # incorrect.  In the case of alias6, "IPv6" will be considered the
  # value which it is not -- it is the first word of the
  # description.  The format changes width as well.  e.g. here is the
  # same attribute for a different device:
  #   alias6                      IPv6 Alias including Prefix Length            True
  # We can consider this a ToDo item.
  LINE_REGEXP = /\A(?<attr>\S+)\s+(?<value>\S+)\s+(?<desc>.*)(?<alter>(True|False)).*\Z/
  
  # Scans the lines capture by the lsattr_elfoo class and tries to
  # determine the attribute name, value, description, and alterable
  # values.  Creates an lsattrs entry in the db which has keys of the
  # logical name for the device and an item which has the fields of
  # +:attr+, +:value+, +:desc+, and +:alter+.
  def self.create(snap)
    db = snap.db
    lsattrs = db.create_item("lsattrs")
    devices = db.devices
    db.each_pair do |key, orig_item|
      next unless (md = NAME_REGEXP.match(key))
      logical_name = md[1]
      driver = db.devices[logical_name].cudv.ddins.sub(/.*\//, '')
      if driver.empty?
        class_name = "lsattr"
      else
        class_name = "lsattr_#{driver}"
      end
      klass = get_class(class_name, Lsattr)
      orig_item = orig_item.first if orig_item.is_a?(Array)
      new_item = klass.new(orig_item.to_text, db)
      new_item.to_text.each_line do |line|
        fail "lsattr line did not match: '#{line}'" unless (md = LINE_REGEXP.match(line))
        attr = md[:attr]
        value = md[:value]
        value = value.to_i if /\A[0-9]+\Z/.match(value)
        target = Item.new("", db)
        target[:value] = value
        target[:desc] = md[:desc]
        target[:alter] = md[:alter]
        new_item[attr] = target
      end
      lsattrs[key] = new_item
      devices[logical_name]['lsattr'] = new_item if devices.has_key?(logical_name)
    end
  end
  Snapper.add_snap_processor(self)
end
