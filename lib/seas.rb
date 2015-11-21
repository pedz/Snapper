require_relative 'item'
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
        new_value['Devices'] = db.devices
        db.devices[key] = new_value
        seas[key] = new_value
      end
    end
    snap.print_list.add(seas, 25)
  end

  Snapper.add_klass(self)
end
