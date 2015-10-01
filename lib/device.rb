require_relative 'logging'

class Device < Hash
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Device uses.

  SKIP_LINES = /\A=+\Z/
  def format(prefix = "")
    puts "#{prefix}#{self['CuDv']['name']} #{self['CuDv']['ddins']}"
    self['Netstat_v'].to_text.each_line do |line|
      puts "#{prefix}  #{line}" unless SKIP_LINES.match(line)
    end
    self['Lsattr_el'].each_line do |line|
      puts "#{prefix}  #{line}"
    end
  end
end
