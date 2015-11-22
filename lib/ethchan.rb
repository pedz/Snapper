require_relative 'device'
require_relative 'logging'

# A class for ether channels
class Ethchan < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
