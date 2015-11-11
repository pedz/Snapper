require_relative 'device'
require_relative 'logging'

class Ethchan < Device
  include Logging
  LOG_LEVEL = Logger::INFO

  def print(options, indent = 0, prefix = "")
    super
    indent += 1
    attributes.adapter_names.value.split(',').each do |adapter_name|
      @db.devices[adapter_name].print(options, indent, prefix)
    end
  end
end
