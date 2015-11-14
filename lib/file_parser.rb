require_relative 'logging'
require_relative 'item'
require_relative 'db'
require 'json'

# The base type for all things in the database.
class FileParser
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level used by the FileParser class

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
