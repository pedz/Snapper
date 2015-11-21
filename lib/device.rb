require_relative 'logging'
require_relative 'item'

class Device < Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Device uses.

  def initilize
    super
    self[:printed] = false
  end
end
