require_relative 'device'

class Fscsi < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
