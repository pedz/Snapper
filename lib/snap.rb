require_relative 'db'
require_relative 'list'
require_relative 'logging'
require_relative 'print_list'
require_relative 'alert'
require_relative 'print'
require 'pathname'

# The body of information contained within a single snap.
class Snap
  include Print
  
  def Snap.bos_vrmf_map
    return @bos_vrmf_map if @bos_vrmf_map
    Hash[(Pathname.new(__FILE__).parent.parent + 'bos_vrmf_map').readlines.map do |line|
      a, b = line.chomp.split(' ')
      a = "%02d.%02d.%04d.%04d" % a.split('.')
      [ a, b ]
    end]
  end

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

  # @return [Boolean] True when no CuDv entries are found.  The snap
  # is considered empty in this case.
  def empty?
    @db['CuDv'].nil?
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

  # @return [String] Returns the VIOS Level such as 2.2.3.1 from the
  #   <tt>svCollect/VIOS.level</tt> file or the empty string.
  def vios
    # greps the VIOS Level is 2.2.2.2 line and reports back  just the
    # 2.2.2.2 text
    @vios ||= @db.              # from the db
      vios_level.               # the svCollect/VIOS.level file
      to_text.                  # the text from that file
      split("\n").              # split into lines
      grep(/VIOS Level/)[0].    # grep for 'VIOS Level'; use first hit
      split(' ')[3]             # split into words, return 4th word
  rescue
    @vios = ""
  end

  # @return [String] Maps the vrmf level of bos.mp64 to a service pack
  #   name.  If something goes wrong, the empty string is returned.
  def service_pack
    @service_pack ||= (Snap.bos_vrmf_map[@db.lslpp_lc['bos.mp64'].vrmf] ||
                       "bos.mp64: #{@db.lslpp_lc['bos.mp64'].vrmf}")
  rescue
    @service_pack = ""
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
