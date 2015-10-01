require_relative 'logging'

class Print
  # Passed an array of Db
  def self.out(db_list)
    top = db_list[0]
    devices = top['Devices'][0]
    top['Netstat_in'][0].to_hash.each_pair do |interface, value|
      puts "#{interface} mtu:#{value[:mtu]} mac:#{value[:mac]} ipkts:#{value[:ipkts]} ierrs:#{value[:ierrs]} opkts:#{value[:opkts]} oerrs:#{value[:oerrs]}"
      adapter = interface.sub(/e[nt]/, "ent")
      device = devices[adapter]
      device.format("  ")
      if device['CuDv']['ddins'] == "ethchandd"
        device['attributes']['adapter_names']['value'].split(',').each do |adapter_name|
          devices[adapter_name].format("    ")
        end
      end
    end
  end
end
