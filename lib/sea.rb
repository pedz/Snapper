require_relative 'device'
require_relative 'logging'

class Sea < Device
  include Logging
  LOG_LEVEL = Logger::INFO
end
