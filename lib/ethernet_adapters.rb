require_relative 'devices'
require_relative 'seas'

class Ethernet_adapters < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    adapters = db.create_item("ethernet_adapters")
    db.devices.each_pair do |key, value|
      if /\Aent[0-9]+\Z/.match(key)
        adapters[key] = value
      end
    end
    snap.add_item(adapters, 50)
  end

  Snapper.add_snap_processor(self)
end
