require_relative 'devices'
require_relative 'logging'

class Ethchans < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def self.create(snap)
    db = snap.db
    db.devices.each_pair do |key, value|
      if value.cudv.pddvln == "adapter/pseudo/ibm_ech"
        new_value = Ethchan.new(value.to_text, value.to_hash, db)
        db.devices[key] = new_value
      end
    end
  end

  Snapper.add_klass(self)
end