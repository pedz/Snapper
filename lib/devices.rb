require_relative 'logging'

class Devices < Hash
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Devices uses.

  def self.create(db_list)
    db_list.each do |db|
      cudvs = db['CuDv']

      # pddvs (which may be empty) is a hash by uniquetype
      pddvs = {}
      db['PdDv'].each do |pddv|
        pddv = pddv.to_hash
        pddvs[pddv['uniquetype']] = pddv
      end

      # pdats (which may be empty) is a hash by uniquetype of hashes by attribute name
      pdats = {}
      db['PdAt'].each do |pdat|
        pdat = pdat.to_hash
        uniquetype = pdat['uniquetype']
        attribute = pdat['attribute']
        pdats[uniquetype] ||= {}
        pdats[uniquetype][attribute] = pdat
      end

      # cuats is hash by device name of hashes by attribute name
      cuats = {}
      db['CuAt'].each do |cuat|
        cuat = cuat.to_hash
        name = cuat['name']
        attribute = cuat['attribute']
        cuats[name] ||= {}
        cuats[name][attribute] = cuat
      end

      netstat_v = db['Netstat_v'][0].to_hash

      devices = Devices.new
      cudvs.each do |cudv|
        cudv = cudv.to_hash
        name = cudv['name']
        device = Device.new
        devices[name] = device
        device['CuDv'] = cudv
        device['CuAt'] = cuats[name]
        pddvln = cudv['PdDvLn']
        device['PdDv'] = pddvs[pddvln]
        device['PdAt'] = pdats[pddvln]
        attributes = {}
        (device['PdAt'] || device['CuAt'] || {}).keys.each do |key|
          cuat = cuat[key] if cuat = device['CuAt']
          pdat = pdat[key] if pdat = device['PdAt']
          hash = {}
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
        device['attributes'] = attributes

        if temp = db["Lsattr_el#{name}"]
          device['Lsattr_el'] = temp[0].to_text
        end

        device['Netstat_v'] = (netstat_v[name] || Netstat_v_generic.new(''))
      end
      db.add(devices)
    end
  end
end
