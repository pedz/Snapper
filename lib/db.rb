require_relative 'logging'
require_relative 'hash_mixins'
require_relative 'item'
require_relative 'object'

# A place to store things.  Note that it includes HashMakeMethods.
class Db < Hash
  include Logging
  # default log level is INFO
  LOG_LEVEL = Logger::INFO

  include HashMakeMethods

  # Pulled from one of the files and set by FileParser or one of its
  # subclasses.  Currently the only class that sets this is
  # DotFileParser when general.snap is scanned.
  # @return [DateTime] The date and time the snap was taken
  attr_accessor :date_time

  # Create an item of class name with the given text within the db.
  # Calls Object#get_class to find and create the class if necessary passing
  # it name and base.
  # @param name [String] The starting point of the class to create.
  #   This is munged by {Object#get_class}.
  # @param text [String] The starting text to pass in when the
  #   instance of the class is created.
  # @param base [::new(String, Db)] A class whose +new+ signature is a
  #   string of text and a Db instance.
  def create_item(name, text = "", base = Item)
    logger.debug { "create_item(#{name}, #{text[0 .. 10]}, #{base.name})"}
    klass = get_class(name, base)
    logger.debug { "klass = #{klass}"}
    item = klass.new(text, self)
    add(item)
    item
  end

  # @return [String] If an entry for +hostname+ exists, returns the
  #   Hostname#node_name in that entry, otherwise returns
  #   +UnknownHostname+
  def hostname
    if self['hostname']
      self['hostname'].hostname
    else
      "UnknownHostname"
    end
  end

  # @return [String] If an entry for +hostname+ exists, returns the
  #   Hostname#id_to_partition in that entry, otherwise returns
  #   +UnknownIdToPartition+
  def id_to_partition
    if self['hostname']
      self['hostname'].id_to_partition
    else
      "UnknownIdToPartition"
    end
  end

  # @return [String] If an entry for +hostname+ exists, returns the
  #   Hostname#id_to_system in that entry, otherwise returns
  #   +UnknownIdToSystem+.
  def id_to_system
    if self['hostname']
      self['hostname'].id_to_system
    else
      "UnknownIdToSystem"
    end
  end

  private
  
  # Adds item to the database.  The first item added for a given class
  # creates a new entry in the db for the class name and adds the
  # item.  Thus if the item is class Foo, db['Foo'] will return the
  # item.  The second item creates a two element array with the first
  # item first and the new item second.  Subsequent calls that add
  # items of the same class pushes the item onto the existing array.
  #
  # This simplifies some things but complicates others.  If an array
  # is always created, then there are lots of +[0]+ expressions
  # floating around.  But the current method there are +is_a?(Array)+
  # expressions and code to cope.  Ultimately, the code needs usually
  # do different things if it is one item or a list so the current
  # method ends up saving sometimes and costing nothing extra
  # otherwise.
  #
  # @param item [Object] The item to add.
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
end
