require_relative 'item'
require_relative 'logging'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, etherner_adapters,
# interfaces

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
  def self.process_snap(snap)
    db = snap.db
    cu_dvs = db['CuDv']

    # pd_dvs (which may be empty) is a hash[uniquetype]
    if db['PdDv']
      pd_dvs = Hash[
        db['PdDv'].group_by(&:uniquetype).map do |key, array|
          snap.add_alert("Multiple PdDv entries for #{key}") if array.length > 1
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

    # pd_dvs = Item.new(@db)
    # db['PdDv'] && db['PdDv'].each do |pd_dv|
    #   pd_dv = pd_dv
    #   pd_dvs[pd_dv['uniquetype']] = pd_dv
    # end

    # Result is hash[name][attribute]
    if db['CuAt']
      cu_ats = Hash[ db['CuAt'].group_by(&:name).map do |key, array|
                       [ key, array.group_by(&:attribute) ]
                     end
                   ]
    else
      cu_ats = {}
    end

    # # pd_ats (which may be empty) is a hash by uniquetype of hashes by attribute name
    # pd_ats = Item.new(@db)
    # db['PdAt'] && db['PdAt'].each do |pd_at|
    #   pd_at = pd_at
    #   uniquetype = pd_at['uniquetype']
    #   attribute = pd_at['attribute']
    #   pd_ats[uniquetype] ||= Item.new(@db)
    #   pd_ats[uniquetype][attribute] = pd_at
    # end

    # # cu_ats is hash by device name of hashes by attribute name
    # cu_ats = Item.new(@db)
    # db['CuAt'].each do |cu_at|
    #   cu_at = cu_at
    #   name = cu_at['name']
    #   attribute = cu_at['attribute']
    #   cu_ats[name] ||= Item.new(@db)
    #   cu_ats[name][attribute] = cu_at
    # end

    errs = Item.new(@db)
    db['Errpt'].each do |err|
      name = err['Resource Name']
      (errs[name] ||= List.new).push(err)
    end

    netstat_in = (db['Netstat -in'] ||= {})
    netstat_v = (db['Netstat -v'] ||= {})

    devices = db.create_item("Devices")
    cu_dvs.each do |cu_dv|
      name = cu_dv['name']
      pd_dv_ln = cu_dv['PdDvLn']

      device = Device.new("", db)
      devices[name] = device

      device[:name] = name
      device['CuDv'] = cu_dv
      device['CuAt'] = device_cu_ats = (cu_ats[name] || {})
      device['PdDv'] = pd_dvs[pd_dv_ln]
      device['PdAt'] = device_pd_ats = (pd_ats[pd_dv_ln] || {})

      attributes = Item.new(@db)
      attrs = Item.new(@db)
      (device['PdAt'] || device['CuAt'] || {}).keys.each do |attribute|
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
