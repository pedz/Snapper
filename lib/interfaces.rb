require_relative 'devices'
# We must execute after the device has been converted to a sea or
# ethchan
require_relative 'seas'
require_relative 'ethchans'
require_relative 'logging'
require_relative 'snapper'

# A snap processor that runs and creates an Intefaces container in the
# top level db.
class Interfaces < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # This is where the ifconfig -a output needs to be merged in.  The
  # only added field is +:adapter+ which is the Device entry for the
  # underlying device after the name has been modified.  e.g. en0
  # points to the ent0 Device.
  def self.create(snap)
    db = snap.db
    interfaces = db.create_item("Interfaces")
    snap.db.netstat_in.each_pair do |key, item|
      if db['Devices'] && (md = /\Ae[nt](?<number>[0-9]+)\z/.match(item.name))
        device_name = "ent#{md[:number]}"
        if adapter = db['Devices'][device_name]
          item[:adapter] = adapter
        end
      end
      interfaces[key] = item
    end
    snap.add_item(interfaces, 10)
  end
  Snapper.add_snap_processor(self)
end
