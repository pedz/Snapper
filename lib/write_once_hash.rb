require_relative 'logging'
require_relative 'hash_mixins'

# A hash but a value can only be written once.  This is done to make
# sure the various parsers are correctly pasing their input.
class WriteOnceHash < Hash
  include Logging
  LOG_LEVEL = Logger::INFO # The log level that WriteOnceHash will use

  include HashWriteOnce
end
