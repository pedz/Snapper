require_relative 'logging'
require_relative 'list'
require_relative 'print_list'

# The body of information contained within a single snap.
class Snap
  # @return [Db] The Db database passed
  attr_reader :db

  # @return [String] The top level directory where the snap resides
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
  # @param priority [Integer] The position (smallest first) of the
  #   item.
  def add_item(item, priority)
    @print_list.add(item, priority)
  end

  # Print the Snap out which prints out the info about the Snap along
  # with the list of {Alert Alerts} and the list of {Item Items} the
  # were added via {Snap#add_item add_item} nested one level deeper.
  # @param context [Context] The context to use for printing.
  def print(context)
    context.output("Snap taken #{date_time}")
    @alerts.print(context.nest)
    @print_list.print(context.nest)
    context
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
