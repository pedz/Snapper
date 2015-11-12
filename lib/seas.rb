require_relative 'devices'
require_relative 'logging'

class Seas < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    seas = Seas.new(db)
    db.devices.each_pair do |key, value|
      if value.cudv.pddvln == "adapter/pseudo/sea"
        new_value = Sea.new(value.to_text, value.to_hash, db)
        db.devices[key] = new_value
        seas[key] = new_value
      end
    end
    db.add(seas)
    snap.print_list.add(seas, 25)
  end

  Snapper.add_klass(self)

  def print(context)
    self.each_value.print_list(context.nest) do |context, device|
      #ugly just to prevent double blank lines.
      unless device.printed
        context = device.print(context)
        if options.level > 0
          output(context, "")
        end
      end
      context
    end
    context
  end
end
