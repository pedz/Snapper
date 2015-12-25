require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, interfaces
require_relative 'devices'

# A snap processor that finds ether channels and converts their
# Devices entry into the Ethchan subclass.  Creates and populates the
# adapter_names and backup_adapter fields as well.
class Ethchans < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Runs through the Devices in the snap looking for ones with
  # uniquetype of +adapter/pseudo/ibm_ech+.  It converts the Devices
  # entry for these into the {Ethchan} subclass as well as creates and
  # populates the +adapter_names+ and +backup_adapter+ fields.
  # @param snap [Snap] The snap to process.
  def self.process_snap(snap)
    db = snap.db
    db.devices.each_pair do |key, value|
      if value.cu_dv.pd_dv_ln == "adapter/pseudo/ibm_ech"
        logger.debug { "Converting #{key} into a Ethchan"}
        new_value = value.subclass(Ethchan)
        new_value[:adapter_names] = List.new
        value.attributes.adapter_names.value.split(',').each do |adapter_name|
          new_value[:adapter_names].push(db['Devices'][adapter_name])
        end
        unless value.attributes['backup_adapter'] &&
               (backup_adapter = value.attributes['backup_adapter'].value) == "NONE"
          new_value[:backup_adapter] = db['Devices'][backup_adapter]
        end
        db.devices[key] = new_value
      end
    end
  end

  Snapper.add_snap_processor(self)
end
