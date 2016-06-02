require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, etherner_adapters,
# interfaces
require_relative 'vlans'

# Finds all the ethernet adapters.  This is done by looking at the
# name of the device and selecting those that match ent[0-9]+
class EthernetAdapters < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Regexp that matches the names of ethernet adapters.
  ETHERNET_NAME_REGEXP = /\Aent[0-9]+\Z/
  
  # Gathers all the ethernet adapters into the Etnernet_adapters item
  # within the db and adds a print item at level 50 which will cause
  # all the unused ethernet adapters to be listed.
  # @param snap [Snap] The snap to process.
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    logger.debug { "create called"}
    db = snap.db
    adapters = db.create_item("EthernetAdapters")
    db.devices.each_pair do |logical_name, device|
      if ETHERNET_NAME_REGEXP.match(logical_name)
        adapters[logical_name] = device
      end
      if (cu_dv = device.cu_dv) &&
         cu_dv.pd_dv_ln == "adapter/vdevice/IBM,l-lan" &&
         device[:is_trunk] != true &&
         (entstat = device['entstat']) &&
         entstat['Trunk Adapter'] == "True"
        snap.add_alert("#{logical_name} is a Trunk Adapter")
      end
    end
    snap.add_item(adapters, 50)
  end

  Snapper.add_snap_processor(self)
end
