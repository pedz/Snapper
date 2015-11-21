require_relative 'device'
require_relative 'logging'

class Ethchan < Device
  include Logging
  LOG_LEVEL = Logger::INFO
end
