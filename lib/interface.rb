require_relative "item"

class Interface < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
