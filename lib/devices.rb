require_relative 'item'
require_relative 'logging'
require_relative 'snapper'

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
  def self.create(snap)
    db = snap.db
    cudvs = db['Cudv']

    # pddvs (which may be empty) is a hash by uniquetype
    pddvs = Item.new(@db)
    db['Pddv'] && db['Pddv'].each do |pddv|
      pddv = pddv
      pddvs[pddv['uniquetype']] = pddv
    end

    # pdats (which may be empty) is a hash by uniquetype of hashes by attribute name
    pdats = Item.new(@db)
    db['Pdat'] && db['Pdat'].each do |pdat|
      pdat = pdat
      uniquetype = pdat['uniquetype']
      attribute = pdat['attribute']
      pdats[uniquetype] ||= Item.new(@db)
      pdats[uniquetype][attribute] = pdat
    end

    # cuats is hash by device name of hashes by attribute name
    cuats = Item.new(@db)
    db['Cuat'].each do |cuat|
      cuat = cuat
      name = cuat['name']
      attribute = cuat['attribute']
      cuats[name] ||= Item.new(@db)
      cuats[name][attribute] = cuat
    end

    errs = Item.new(@db)
    db['Errpt'].each do |err|
      name = err['Resource Name']
      (errs[name] ||= List.new).push(err)
    end

    netstat_in = (db['Netstat_in'] ||= {})
    netstat_v = (db['Netstat_v'] ||= {})

    devices = db.create_item("Devices")
    cudvs.each do |cudv|
      cudv = cudv
      name = cudv['name']
      device = Device.new("", db)
      devices[name] = device
      device[:name] = name
      device['CuDv'] = cudv
      device['CuAt'] = cuats[name]
      pddvln = cudv['PdDvLn']
      device['PdDv'] = pddvs[pddvln]
      device['PdAt'] = pdats[pddvln]
      attributes = Item.new(@db)
      (device['PdAt'] || device['CuAt'] || Item.new(@db)).keys.each do |key|
        cuat = cuat[key] if cuat = device['CuAt']
        pdat = pdat[key] if pdat = device['PdAt']
        hash = Item.new(@db)
        unless pdat.nil?
          %w{ attribute uniquetype deflt values width type generic rep nls_index }.each do |field|
            hash[field] = pdat[field]
          end
          # Assume the default is set
          hash['value'] = pdat['deflt']
        end
        unless cuat.nil?
          %w{ name attribute value type generic rep nls_index }.each do |field|
            hash[field] = cuat[field]
          end
        end
        attributes[key] = hash
      end
      device['lsattr'] = nil  # filled in by Lsattr later
      device['attributes'] = attributes
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
