require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, lsattr, ethernets, ethchans, seas, vlans,
# vnic_servers, ethernet_adapters, interfaces
require_relative 'vlans'
require_relative 'vnic_server'

class VnicServers < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Regexp that matches the names of ethernet adapters.
  VNIC_SERVER_NAME_REGEXP = /\Avnicserver[0-9]+\Z/

  def self.process_snap(snap, options)
    logger.debug { "create called"}
    db = snap.db
    devices = db.devices
    adapters = db.create_item("VnicServers")
    devices.each_pair do |logical_name, device|
      if VNIC_SERVER_NAME_REGEXP.match(logical_name)
        lsattr = device.lsattr
        new_item = device.subclass(VnicServer)
        devices[logical_name] = adapters[logical_name] = new_item
        if lsattr
          new_item[:eth_dev_loc] = lsattr.value(:eth_dev_loc) || "Unknown"
          name = new_item[:eth_dev_name] = lsattr.value(:eth_dev_name) || "Unknown"
          new_item[:eth_dev] = devices[name]
        else
          new_item[:eth_dev_loc] = "Unknown"
          new_item[:eth_dev_name] = "Unknown"
          new_item[:eth_dev] = nil
        end
      end
    end
    snap.add_item(adapters, 40)
  end

  Snapper.add_snap_processor(self)
end
