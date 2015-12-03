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
  # io is usually a File and path is the path the file came from.  But
  # for testing, path can be nil and io is a StringIO.  db is the
  # database.
  def initialize(io, db, path = nil)
    @io, @db, @path = io, db, path
  end

  ##
  # Abstract parse method
  def parse
    fatal "Please override this method"
  end
end
