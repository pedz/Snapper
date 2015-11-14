require_relative 'logging'
require_relative 'hash_mixins'
require_relative 'item'

# A place to store things
class Db < Hash
  include Logging
  LOG_LEVEL = Logger::INFO      # Logging level for the Db class

  include HashMakeMethods

  ##
  # Create an item within the db.
  def create_item(name, text = "", base = Item)
    klass = get_class(name, base)
    item = klass.new(text, self)
    add(item)
    item
  end

  private
  
  # Adds item into the database by pushing item onto the table from
  # the database who name matches the class of the item.
  def add(item)
    klass = item.class.to_s
    if self[klass].nil?
      self[klass] = item
    elsif self[klass].respond_to?(:push)
      self[klass].push(item)
    else
      self[klass] = [ self[klass], item ]
    end
  end

  # Gets the class "name" and creates the class if necessary using
  # base as the super class
  def get_class(name, base)
    # Doing this with eval causes the inherited class method of the
    # base (usually Item) to be called with class that has a name.
    # Otherwise, the classname is something like
    # #<Class:0x1234567890abcdef>
    name = name.gsub(/ /, '').gsub(%r{[^a-zA-Z0-9]},'_').capitalize
    eval("class ::#{name} < #{base}; end") unless ::Module.const_defined?(name)
    ::Module.const_get(name)
  end
end
