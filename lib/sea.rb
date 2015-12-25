require_relative 'device'
require_relative 'logging'

# A class for Sea so it can have its own Filter rules.  See Seas for
# how they get created.
class Sea < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
