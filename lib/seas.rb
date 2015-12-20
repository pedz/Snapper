require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, interfaces
require_relative 'ethchans'

# A snap processor that runs through the Devices looking Sea devices.
# This processor must run after Devices but before Vlans and
# Interfaces.
class Seas < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Runs through Devices looking for ones that have a PdDvLn value of
  # +adapter/pseudo/sea+.  When one is found the entry in Devices is
  # altered to be a Sea and at the same time, the real_adapter,
  # virt_adapters, and ctl_chan attributes are added and filled in
  # based upon the attribute values found in the Device item.
  #
  # Creates an {Alert Alert} if +adapter_reset+ is set to +yes+.
  #
  # @param snap [Snap] The snap to process.
  def self.create(snap)
    db = snap.db
    seas = db.create_item("seas")
    db.devices.each_pair do |key, device|
      if device.cudv.pddvln == "adapter/pseudo/sea"
        logger.debug { "Converting #{key} into a Sea"}
        new_device = device.subclass(Sea)
        new_device[:real_adapter] = db['Devices'][device.attributes.real_adapter.value]
        new_device[:virt_adapters] = List.new
        device.attributes.virt_adapters.value.split(',').each do |adapter_name|
          new_device[:virt_adapters].push(db['Devices'][adapter_name])
        end
        new_device[:ctl_chan] = db['Devices'][device.attributes.ctl_chan.value]
        db.devices[key] = new_device
        seas[key] = new_device

        if (device.attributes['adapter_reset'] && device.attributes.adapter_reset.value != "no")
          snap.add_alert("adapter_reset on #{key} set to #{device.attributes.adapter_reset.value.inspect}")
        end
      end
    end
    snap.add_item(seas, 25)
  end

  Snapper.add_snap_processor(self)
end
