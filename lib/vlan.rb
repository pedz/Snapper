require_relative "logging"
require_relative "item"

# Class for the vlandd devices.
class Vlan < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
  # @param remove me
end
