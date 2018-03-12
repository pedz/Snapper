require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, lsattr, ethernets, ethchans, seas, vlans,
# vnic_servers, ethernet_adapters, interfaces
require_relative 'seas'

# A snap processor which finds vlan adapters and converts their type
# much like Ethchans does.
class Vlans < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Runs through the Devices of the Snap looking for devices with a
  # PdDvLn of +adapter/vlan/eth+ and converts them to a Vlan.
  # @param snap [Snap] The snap to review.
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    db = snap.db
    devices = db.devices
    devices.each_pair do |key, value|
      if value.cu_dv.pd_dv_ln == "adapter/vlan/eth"
        logger.debug { "Converting #{key} into a Vlan"}
        new_value = value.subclass(Vlan)
        new_value[:base_adapter] = db['Devices'][value.attrs[:base_adapter]]
        logger.debug { "base adapter is #{new_value[:base_adapter].class}"}
        devices[key] = new_value
      end
    end
  end

  Snapper.add_snap_processor(self)
end
