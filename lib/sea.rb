require_relative 'device'
require_relative 'logging'

class Sea < Device
  include Logging
  LOG_LEVEL = Logger::INFO

  def print(options, indent = 0, prefix = "")
    super
    indent += 1
    attributes.real_adapter.value.split(',').each do |adapter_name|
      @db.devices[adapter_name].print(options, indent, prefix)
    end
    attributes.virt_adapters.value.split(',').each do |adapter_name|
      @db.devices[adapter_name].print(options, indent, prefix)
    end
    attributes.ctl_chan.value.split(',').each do |adapter_name|
      @db.devices[adapter_name].print(options, indent, prefix)
    end
  end
end
