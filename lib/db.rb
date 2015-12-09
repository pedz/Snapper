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

  ##
  # Pulled from one of the files and set by FileParser or one of its
  # subclasses.  Currently the only class that sets this is
  # DotFileParser when general.snap is scanned.
  attr_accessor :date_time

  # Create an item of class name with the given text within the db.
  # Calls Object#get_class to find and create the class if necessary passing
  # it name and base.
  def create_item(name, text = "", base = Item)
    klass = get_class(name, base)
    item = klass.new(text, self)
    add(item)
    item
  end

  # If an entry for +hostname+ exists, returns the Hostname#node_name
  # in that entry, otherwise returns +UnknownHostname+
  def hostname
    if self['hostname']
      self.hostname.hostname
    else
      "UnknownHostname"
    end
  end

  # If an entry for +hostname+ exists, returns the
  # Hostname#id_to_partition in that entry, otherwise returns
  # +UnknownIdToPartition+
  def id_to_partition
    if self['hostname']
      self.hostname.id_to_partition
    else
      "UnknownIdToPartition"
    end
  end

  # If an entry for +hostname+ exists, returns the
  # Hostname#id_to_system in that entry, otherwise returns
  # +UnknownIdToSystem+.
  def id_to_system
    if self['hostnam']
      self.hostname.id_to_system
    else
      "UnknownIdToSystem"
    end
  end

  private
  
  # Adds item into the database by pushing item onto the table from
  # the database whose name matches the class of the item.
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
