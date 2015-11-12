require_relative 'device'
require_relative 'logging'

class Ethchan < Device
  include Logging
  LOG_LEVEL = Logger::INFO

  def print(context)
    super
    attributes.adapter_names.value.split(',').print_list(context.nest) do |context, adapter_name|
      @db.devices[adapter_name].print(context)
    end
    context
  end
end
