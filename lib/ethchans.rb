require_relative 'devices'
require_relative 'logging'
require_relative 'snapper'

class Ethchans < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    db.devices.each_pair do |key, value|
      if value.cudv.pddvln == "adapter/pseudo/ibm_ech"
        new_value = value.subclass(Ethchan)
        new_value[:adapter_names] = List.new
        value.attributes.adapter_names.value.split(',').each do |adapter_name|
          new_value[:adapter_names].push(db['Devices'][adapter_name])
        end
        db.devices[key] = new_value
      end
    end
  end

  Snapper.add_klass(self)
end
