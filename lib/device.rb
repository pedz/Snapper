require_relative 'logging'
require_relative 'item'

class Device < Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Device uses.

  SKIP_LINES = /\A=+\Z/
  def print(db_list, prefix = "")
    puts "#{prefix}#{self['CuDv']['name']} #{self['CuDv']['ddins']}"
    self['Netstat_v'].to_text.each_line do |line|
      puts "#{prefix}  #{line}" unless SKIP_LINES.match(line)
    end
    self['Lsattr_el'].each_line do |line|
      puts "#{prefix}  #{line}"
    end
    if self['CuDv']['ddins'] == "ethchandd"
      self['attributes']['adapter_names']['value'].split(',').each do |adapter_name|
        db_list[adapter_name].print(db_list, prefix + "    ")
      end
    end
    if self['CuDv']['ddins'] == "seadd"
      self['attributes']['real_adapter']['value'].split(',').each do |adapter_name|
        db_list[adapter_name].print(db_list, prefix + "    ")
      end
      self['attributes']['virtual_adapters']['value'].split(',').each do |adapter_name|
        db_list[adapter_name].print(db_list, prefix + "    ")
      end
      self['attributes']['control_adapter']['value'].split(',').each do |adapter_name|
        db_list[adapter_name].print(db_list, prefix + "    ")
      end
    end
  end
end
