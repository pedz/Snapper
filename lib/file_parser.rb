require_relative 'logging'
require_relative 'item'
require_relative 'db'
require 'json'

# The base type for the various parsers.  This is a virtual class in
# that its parse method must be overriden.
class FileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  ##
  # The original text of the entry as io
  # The database that the item will be part of as db
  def initialize(io, db)
    @io, @db = io, db
  end

  ##
  # Abstract parse method
  def parse
    fatal "Please override this method"
  end
end
