require_relative 'devices'
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
        db.devices[key] = new_value
        seas[key] = new_value
      end
    end
    snap.print_list.add(seas, 25)
  end

  Snapper.add_klass(self)

  def print(context)
    self.each_value.print_list(context) do |context, device|
      #ugly just to prevent double blank lines.
      unless device.printed
        context = device.print(context)
        if context.options.level > 0
          output(context)
        end
      end
      context
    end
    context
  end
end
