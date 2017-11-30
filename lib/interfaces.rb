require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethernets, ethchans, seas, vlans,
# ethernet_adapters, interfaces
require_relative 'ethernet_adapters'

# A snap processor that runs and creates an Intefaces container in the
# top level db.
class Interfaces < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # This is where the ifconfig -a output needs to be merged in.  The
  # only added field is +:adapter+ which is the Device entry for the
  # underlying device after the name has been modified.  e.g. en0
  # points to the ent0 Device.
  # @param snap [Snap] The snap to process
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    db = snap.db
    interfaces = db.create_item("Interfaces")
    ifconfig_a = db.ifconfig_a
    netstat_in = db.netstat_in
    # netstat -in is always in the snap while ifconfig -a is there
    # only for newer snaps.  So we walk through netstat_in and add in
    # the ifconfig -a information if it is available.
    netstat_in.each_pair do |key, item|
      if db['Devices'] && (md = /\Ae[nt](?<number>[0-9]+)\z/.match(item.name))
        device_name = "ent#{md[:number]}"
        if adapter = db['Devices'][device_name]
          logger.debug { "adapter is #{adapter.class}"}
          item[:adapter] = adapter
        end
      end

      # Because ifconfig may or may not be present, rather than
      # merge the ifconfig data into the interface, I just add it as
      # the whole entity so one test can determine if it is present
      # or not.
      if ifconfig_a && (ifconfig = ifconfig_a[key])
        item[:ifconfig] = ifconfig
        # We sniff the sequence of addresses to make sure they are
        # the same between netstat -in and ifconfig -a
        a = item[:addrs]
        b = ifconfig[:addrs]
        a = a.map { |h| h[:address] } if a
        b = b.map { |h| h[:address] } if b
        if a != b
          snap.add_alert("#{key} has addresses in different sequence between ifconfig -a and netstat -an")
        end
      end
      interfaces[key] = item
    end
    snap.add_item(interfaces, 10)
  end
  Snapper.add_snap_processor(self)
end
