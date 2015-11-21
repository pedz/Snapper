require_relative "item"

class Interface < Item
  include Logging
  LOG_LEVEL = Logger::INFO
end
