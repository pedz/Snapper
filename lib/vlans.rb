require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, interfaces
require_relative "seas"

# Finds vlan adapters and converts their type much like ethchans do.
class Vlans < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    db.devices.each_pair do |key, value|
      if value.cudv.pddvln == "adapter/vlan/eth"
        logger.debug { "Converting #{key} into a Vlan"}
        new_value = value.subclass(Vlan)
        new_value[:base_adapter] = db['Devices'][value.attributes.base_adapter.value]
        logger.debug { "base adapter is #{new_value[:base_adapter].class}"}
        db.devices[key] = new_value
      end
    end
  end

  Snapper.add_snap_processor(self)
end
