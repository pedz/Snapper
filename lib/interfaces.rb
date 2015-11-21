require_relative 'devices'
require_relative 'logging'

class Interfaces < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    interfaces = db.create_item("Interfaces")
    snap.db.netstat_in.each_pair do |key, item|
      interfaces[key] = item
      item['Devices'] = db.devices
    end
    snap.print_list.add(interfaces, 10)
  end
  Snapper.add_klass(self)
end
