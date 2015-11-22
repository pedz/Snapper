require_relative 'devices'
# Must run after ethchans have been converted
require_relative 'seas'
require_relative 'logging'

class Seas < Item
  include Logging
  LOG_LEVEL = Logger::INFO

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

  Snapper.add_klass(self)
end
