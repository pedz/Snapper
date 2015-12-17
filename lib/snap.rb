require_relative 'logging'
require_relative 'list'
require_relative 'print_list'

class Snap
  # The Db database passed
  attr_reader :db

  # The top level directory where the snap resides
  attr_reader :dir

  # Must pass in the :dir (directory to the snap) and :db (the Db used
  # in the parsing).  Other options can be :alerts (a List of Alerts)
  # and :print_list (a PrintList)
  def initialize(options)
    fail "Must have :db and :dir entries" unless options.has_key?(:db) and options.has_key?(:dir)
    @dir = options[:dir]
    @db = options[:db]
    @alerts = (options[:alerts] || List.new)
    @print_list = (options[:print_list] || PrintList.new)
  end

  # Returns Db#date_time from the contained db.
  def date_time
    @db.date_time
  end

  # Returns Db#hostname
  def hostname
    @db.hostname
  end

  # Returns Db#id_to_partition
  def id_to_partition
    @db.id_to_partition
  end

  # Returns Db#id_to_system
  def id_to_system
    @db.id_to_system
  end
  
  def <=>(b)
    self.date_time <=> b.date_time
  end

  def add_alert(text)
    @alerts << Alert.new(text, @db)
  end

  # Adds an item to be printed along with its priority in the print
  # list
  def add_item(item, priority)
    @print_list.add(item, priority)
  end

  # prints the list of items added according to the supplied options.
  def print(context)
    @alerts.print(context)
    @print_list.print(context)
  end

  def to_json(options = {})
    {
      dir: @dir,
      db: @db,
      alerts: @alerts
    }.to_json(options)
  end
end
