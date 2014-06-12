require_relative 'logging'

# A hash but a value can only be written once.
class WriteOnceHash < Hash
  include Logging
  # The log level that WriteOnceHash will use
  LOG_LEVEL = Logger::INFO

  # same as []= for hash except it will fail if the field already
  # exists in the hash.  All of this is to just make sure that the
  # parsers are actually correctly parsing.
  def []=(field, value)
    fail "Overwriting value #{field}" if key?(field)
    logger.debug { "Adding field: '#{field}' = '#{value}'" }
    super
  end
end
