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

  ##
  # Create an item
  def create_item(name, db, text = "", base = Item)
    name = canonicalize(name)
    klass = get_class(name, base)
    item = klass.new(text, db)
    db.add(item)
    item
  end

  private
  
  # Converts a string into a consistent name for a Class.  blanks are
  # removed and any non-alphanumeric characters are converted to
  # underscores.  Then the result is capitalized.
  def canonicalize(name)
    name.gsub(/ /, '').gsub(%r{[^a-zA-Z0-9]},'_').capitalize
  end

  # Gets the class "name" and creates the class if necessary using
  # base as the super class
  def get_class(name, base)
    # Doing this with eval causes the inherited class method of the
    # base (usually Item) to be called with class that has a name.
    # Otherwise, the classname is something like
    # #<Class:0x1234567890abcdef>
    eval("class ::#{name} < #{base}; end") unless ::Object.const_defined?(name)
    ::Object.const_get(name)
  end
end
