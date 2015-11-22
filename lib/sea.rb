require_relative 'device'
require_relative 'logging'

class Sea < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
