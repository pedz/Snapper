require_relative 'item'
require_relative 'logging'
require_relative 'snapper'
# The load order is devices, ethernets, ethchans, seas, vlans,
# ethernet_adapters, interfaces

# A container in the db that has an entry for each logical device
# found in CuDv.  The key for the entry is the logical name
# (e.g. ent0) and the value is a Device.
class Devices < Item
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Creates the +devices+ entry in the db and fills it with an entry
  # for each customized device by its logical name.  Note that
  # {Lsattr} creates the +lsattr+ entry within the device.
  #
  # Creates an Alert if +ipsec_v4+ or +ipsec_v6+ is configured.
  #
  # @param snap [Snap] The snap to process.
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    db = snap.db
    cu_dvs = db['CuDv']
    if cu_dvs.nil?
      $stderr.puts("No CuDv entries found.") 
      $stderr.puts("Skipping this snap")
      return
    end

    # pd_dvs (which may be empty) is a hash[uniquetype]
    if db['PdDv']
      pd_dvs = Hash[
        db['PdDv'].group_by(&:uniquetype).map do |key, array|
          if array.length > 1 && options.level > 3
            snap.add_alert("Multiple PdDv entries for #{key}")
          end
          [ key, array[0] ]
        end
      ]
    else
      pd_dvs = {}
    end

    # Result is hash[uniquetype][attribute]
    if db['PdAt']
      pd_ats = Hash[
        db['PdAt'].group_by(&:uniquetype).map do |uniquetype_key, uniquetype_array|
          [ uniquetype_key, Hash[ uniquetype_array.group_by(&:attribute) ] ]
        end
      ]
    else
      pd_ats = {}
    end

    # Result is hash[name][attribute]
    if db['CuAt']
      cu_ats = Hash[ db['CuAt'].group_by(&:name).map do |key, array|
                       [ key, array.group_by(&:attribute) ]
                     end
                   ]
    else
      cu_ats = {}
    end

    errs = Item.new(@db)
    db['Errpt'].each do |err|
      name = err['Resource Name']
      (errs[name] ||= List.new).push(err)
    end

    netstat_in = (db['Netstat -in'] ||= {})
    netstat_v = (db['Netstat -v'] ||= {})
    if netstat_v.is_a? Array
      fail "\nFound multiple tcpip.snap files within specified directory.\nPlease clean up testcase first"
    end

    devices = db.create_item("Devices")
    cu_dvs.each do |cu_dv|
      name = cu_dv['name']
      pd_dv_ln = cu_dv['PdDvLn']
      logger.debug { "#{name} #{pd_dv_ln}"}
      device = Device.new("", db)
      devices[name] = device

      device[:name] = name
      device['CuDv'] = cu_dv
      device['CuAt'] = device_cu_ats = (cu_ats[name] || {})
      device['PdDv'] = pd_dvs[pd_dv_ln]
      device['PdAt'] = device_pd_ats = (pd_ats[pd_dv_ln] || {})
      logger.debug { "device_cu_ats.keys.length=#{device_cu_ats.class}"}
      logger.debug { "device_pd_ats.keys.length=#{device_pd_ats.class}"}
      attributes = Item.new(@db)
      attrs = Item.new(@db)
      temp = device_pd_ats.empty? ? device_cu_ats : device_pd_ats
      temp.keys.each do |attribute|
        logger.debug { "attribute=#{attribute}"}
        attr = Attribute.new(device_cu_ats[attribute], device_pd_ats[attribute])
        attributes[attribute] = attr
        attrs[attribute] = attr.value
      end
      device['attributes'] = attributes
      device['attrs'] = attrs

      device['lsattr'] = nil  # filled in by Lsattr later
      device['errpt'] = errs[name]
      device['entstat'] = netstat_v[name]
      device['netstat_in'] = netstat_in[name]
    end
    %w{ ipsec_v4 ipsec_v6 }.each do |dev|
      snap.add_alert("#{dev} is configured") if devices[dev]
    end
  end

  Snapper.add_snap_processor(self)
end
