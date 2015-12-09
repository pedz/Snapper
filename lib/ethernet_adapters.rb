require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, interfaces
require_relative 'vlans'

# Finds all the ethernet adapters.
class EthernetAdapters
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Gathers all the ethernet adapters into the Etnernet_adapters item
  # within the db and adds a print item at level 50 which will cause
  # all the unused ethernet adapters to be listed.
  def self.create(snap)
    db = snap.db
    adapters = db.create_item("Ethernet_adapters")
    db.devices.each_pair do |key, value|
      if /\Aent[0-9]+\Z/.match(key)
        adapters[key] = value
      end
    end
    snap.add_item(adapters, 50)
  end

  Snapper.add_snap_processor(self)
end
