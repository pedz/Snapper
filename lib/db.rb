
# A generic container with an add method to add elements into the
# container.  The container will actually proxy to methods within the
# items.
class Db
  def initialize
    @db = Hash.new
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
end
