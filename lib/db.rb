require_relative 'logging'
require 'json'

# A "database" in the crudest sense.  It has "tables" which are
# arrays.  The names of the tables is the class of the items within
# the table.
class Db
  include Logging
  # Logging level for the Db class
  LOG_LEVEL = Logger::INFO

  def initialize
    @db = Hash.new
  end

  # Returns the element in the database matching key
  def [](key)
    @db[key]
  end

  # Adds item into the database by pushing item onto the table from
  # the database who name matches the class of the item.
  def add(item)
    table(item.class).push(item)
  end

  # Returns a container called a table that will have only elements
  # of the class as item
  def table(klass)
    @db[klass.to_s] ||= []
  end

  # Converts the database into json
  def to_json(options = {})
    @db.to_json(options)
  end
end
