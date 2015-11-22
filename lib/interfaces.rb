require_relative 'devices'
# We must execute after the device has been converted to a sea or
# ethchan
require_relative 'seas'
require_relative 'ethchans'
require_relative 'logging'
require_relative 'snapper'

class Interfaces < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

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
    snap.print_list.add(interfaces, 10)
  end
  Snapper.add_snap_processor(self)
end
