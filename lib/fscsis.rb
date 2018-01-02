require_relative 'lsattr'

# Finds all devices with a name of fscsi[0-9]+ and converts them into
# an Fscsi type.  Also checks the fc_err_recov is fast_fail and dyntrk
# is set to yes adding alerts to the snap if they are not.
#
# The lsattr output from general.snap is used for this because some
# devices have their defaults set in the unwanted state.
class Fscsis < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Runs through the fscsi devices adding alerts for configurations
  # that are not optimum.  This was suggested by Steve Lang.
  #
  # @param snap [Snap] The snap to process.
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    db = snap.db
    devices = db.devices
    fscsis = db.create_item("Fscsis")
    devices.each_pair do |logical_name, device|
      next unless /fscsi[0-9]+/.match(logical_name)
      fscsi = device.subclass(Fscsi)
      next unless (lsattr = fscsi.lsattr)

      # unless (val = lsattr.value('fc_err_recov')) == "fast_fail"
      #   snap.add_alert("#{logical_name} has fc_err_recov set to #{val}")
      # end

      # unless (val = lsattr.value('dyntrk')) == "yes"
      #   snap.add_alert("#{logical_name} has dyntrk set to #{val}")
      # end

      devices[logical_name] = fscsi
      fscsis[logical_name] = fscsi
    end
  end

  Snapper.add_snap_processor(self)
end
