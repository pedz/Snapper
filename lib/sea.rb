require_relative 'device'
require_relative 'logging'

class Sea < Device
  include Logging
  LOG_LEVEL = Logger::INFO

  def print(context)
    super
    attributes.real_adapter.value.split(',').print_list(context.nest) do |context, adapter_name|
      @db.devices[adapter_name].print(context)
    end
    attributes.virt_adapters.value.split(',').print_list(context.nest) do |context, adapter_name|
      @db.devices[adapter_name].print(context)
    end
    attributes.ctl_chan.value.split(',').print_list(context.nest) do |context, adapter_name|
      @db.devices[adapter_name].print(context)
    end
    context
  end
end
