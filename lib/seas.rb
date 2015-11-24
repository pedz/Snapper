require_relative 'devices'
# Must run after ethchans have been converted
require_relative 'seas'
require_relative 'logging'
require_relative 'snapper'

# A snap processor that runs through the Devices looking Sea devices.
class Seas < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Runs through Devices looking for ones that have a PdDvLn value of
  # +adapter/pseudo/sea+.  When one is found the entry in Devices is
  # altered to be a Sea and at the same time, the real_adapter,
  # virt_adapters, and ctl_chan attributes are added and filled in
  # based upon the attribute values found in the Device item.
  def self.create(snap)
    db = snap.db
    seas = db.create_item("seas")
    db.devices.each_pair do |key, value|
      if value.cudv.pddvln == "adapter/pseudo/sea"
        new_value = value.subclass(Sea)
        new_value[:real_adapter] = db['Devices'][value.attributes.real_adapter.value]
        new_value[:virt_adapters] = List.new
        value.attributes.virt_adapters.value.split(',').each do |adapter_name|
          new_value[:virt_adapters].push(db['Devices'][adapter_name])
        end
        new_value[:ctl_chan] = db['Devices'][value.attributes.ctl_chan.value]
        db.devices[key] = new_value
        seas[key] = new_value
      end
    end
    snap.print_list.add(seas, 25)
  end

  Snapper.add_snap_processor(self)
end
