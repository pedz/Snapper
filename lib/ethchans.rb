require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, etherner_adapters,
# interfaces
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
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    db = snap.db
    db.devices.each_pair do |key, value|
      if value.cu_dv.pd_dv_ln == "adapter/pseudo/ibm_ech"
        logger.debug { "Converting #{key} into a Ethchan"}
        new_value = value.subclass(Ethchan)
        new_value[:adapter_names] = List.new
        value.attrs[:adapter_names].split(',').each do |adapter_name|
          new_value[:adapter_names].push(db['Devices'][adapter_name])
        end
        unless value.attributes['backup_adapter'] &&
               (backup_adapter = value.attrs[:backup_adapter]) == "NONE"
          new_value[:backup_adapter] = db['Devices'][backup_adapter]
        end
        db.devices[key] = new_value
        validate_ethchan(new_value, snap)
      end
    end
  end

  def self.validate_ethchan(ethchan, snap)
    if ethchan.attrs[:mode] == "8023ad"
      list = ethchan.adapter_names.dup
      push ethchan.backup_adapter if ethchan['backup_adapter']
      first = list.shift
      return unless first['entstat'] && first.entstat['partner_state']
      gold = first.entstat
      list.each do |adapter|
        partner = adapter.entstat
        unless gold['Partner System'] == partner['Partner System']
          snap.add_alert("'Partner System' for #{first.name} and #{adapter.name} do not match")
        end
        unless gold['Partner Operational Key'] == partner['Partner Operational Key']
          snap.add_alert("'Partner Operational Key' for #{first.name} and #{adapter.name} do not match")
        end
      end
    end
  end

  Snapper.add_snap_processor(self)
end
