require_relative 'devices'
require_relative 'logging'

class Interfaces < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    interfaces = db.create_item("Interfaces")
    snap.db.netstat_in.each_pair { |key, value| interfaces[key] = value }
    snap.print_list.add(interfaces, 10)
  end

  Snapper.add_klass(self)

  def print(context)
    if context.options.level > 2
      puts "##{"Interfaces".center(78)}#"
    end
    self.each_value.print_list(context.dup)
    context
  end
end
