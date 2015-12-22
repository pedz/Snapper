require_relative 'device'
require_relative 'logging'

# A class for ether channels.  The {Ethchans} snap processor finds and
# fills out the +adapter_names+ and +backup_adapter+ fields.
class Ethchan < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
  # @param  remove me
end
