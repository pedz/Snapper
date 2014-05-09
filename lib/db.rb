
require 'json'

# A generic container with an add method to add elements into the
# container.  The container will actually proxy to methods within the
# items.
class Db
  include Logging

  def initialize
    @db = Hash.new
  end

  def [](key)
    @db[key]
  end

  # Adds item into the container
  def add(item)
    table(item.class).push(item)
  end

  # Returns a container called a table that will have only elements
  # of the class as item
  def table(klass)
    @db[klass.to_s] ||= []
  end

  def keys
    @db.keys
  end

  def to_json(options = {})
    @db.to_json(options)
  end
end
