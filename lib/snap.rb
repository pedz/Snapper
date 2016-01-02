require_relative 'db'
require_relative 'list'
require_relative 'logging'
require_relative 'print_list'
require_relative 'alert'
require_relative 'print'

# The body of information contained within a single snap.
class Snap
  include Print
  
  # @return [Array<Alert>] Array of {Alert}s that has been added to
  #   the Snap.
  attr_reader :alerts

  # @return [PrintList] The print list associated with this snap.
  attr_reader :print_list
  
  # @return [Db] The Db database passed
  attr_reader :db

  # @return [String] The top level directory where the snap resides
  attr_reader :dir

  # Must pass in the :dir (directory to the snap) and :db (the Db used
  # in the parsing).  Other options can be :alerts (a List of Alerts)
  # and :print_list (a PrintList)
  # @raise [RuntimeError] if options do not specify a +:db+ and a
  #   +:dir+ entry.
  def initialize(options)
    fail "Must have :db and :dir entries" unless options.has_key?(:db) and options.has_key?(:dir)
    @dir = options[:dir]
    @db = options[:db]
    @alerts = (options[:alerts] || List.new)
    @print_list = (options[:print_list] || PrintList.new)
  end

  # @return [DateTime] Forwards to {Db#date_time}
  def date_time
    @db.date_time
  end

  # @return [String] The hostname as found by the hostname attribute
  #   of the inet0 device.
  def hostname
    @db.hostname
  end

  # @return [String] The id_to_partition as found by the
  #   id_to_partition attribute of the sys0 device.
  def id_to_partition
    @db.id_to_partition
  end

  # @return [String] The id_to_system attribute as pulled from the
  #   sys0 device.
  def id_to_system
    @db.id_to_system
  end
  
  # Compares with the date_time
  # @param b [Snap] The other Snap to compare to.
  def <=>(b)
    self.date_time <=> b.date_time
  end

  # Add an alert to the Snap
  # @param text [String] The alert text to add
  def add_alert(text)
    @alerts << Alert.new(text, @db)
  end

  # Adds an item to be printed along with its priority in the print
  # list
  # @param item [Item] The item to print out.
  # @param priority [Fixnum] The position (smallest first) of the
  #   item.
  def add_item(item, priority)
    @print_list.add(item, priority)
  end

  # Marshal out the Snap as a JSON object
  # @param options [Hash] usual option hash for to_json
  def to_json(options = {})
    {
      alerts: @alerts,
      db:     @db,
      dir:    @dir
    }.to_json(options)
  end
end
