require_relative 'logging'
require 'json'

# A place to store things
class Db < Hash
  include Logging
  LOG_LEVEL = Logger::INFO      # Logging level for the Db class

  # Adds item into the database by pushing item onto the table from
  # the database who name matches the class of the item.
  def add(item)
    table(item.class).push(item)
  end

  # Returns a container called a table that will have only elements
  # of the class as item
  def table(klass)
    self[klass.to_s] ||= []
  end

  # Converts the database into json
  def to_json(options = {})
    self.to_json(options)
  end
end
