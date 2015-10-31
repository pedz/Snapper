require_relative 'logging'
require 'pp'

class Devices < Hash
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Devices uses.

  def self.create(top)
    top[:snap_list].each do |snap|
      db = snap[:db]
      cudvs = db['Cudv']

      # pddvs (which may be empty) is a hash by uniquetype
      pddvs = {}
      db['Pddv'].each do |pddv|
        pddv = pddv
        pddvs[pddv['uniquetype']] = pddv
      end

      # pdats (which may be empty) is a hash by uniquetype of hashes by attribute name
      pdats = {}
      db['Pdat'].each do |pdat|
        pdat = pdat
        uniquetype = pdat['uniquetype']
        attribute = pdat['attribute']
        pdats[uniquetype] ||= {}
        pdats[uniquetype][attribute] = pdat
      end

      # cuats is hash by device name of hashes by attribute name
      cuats = {}
      db['Cuat'].each do |cuat|
        cuat = cuat
        name = cuat['name']
        attribute = cuat['attribute']
        cuats[name] ||= {}
        cuats[name][attribute] = cuat
      end

      errs = {}
      db['Errpt'].each do |err|
        err = err
        name = err['Resource Name']
        (errs[name] ||= []).push(err)
      end

      netstat_v = db['Netstat_v']

      devices = Devices.new
      cudvs.each do |cudv|
        cudv = cudv
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
        device['errpt'] = errs[name]

        # Its possible to have lsattr -El in more than one place.
        # e.g. vty0 will show up in general/general.snap as well as
        # async/async.snap.  We assume they will all be equal and pick
        # the first one in that case.
        if temp = db["Lsattr_el#{name}"]
          if temp.respond_to? :first
            device['Lsattr_el'] = temp.first
          else
            device['Lsattr_el'] = temp
          end
        end

        device['entstat'] = netstat_v[name]
      end
      db.add(devices)
    end
  end
end
