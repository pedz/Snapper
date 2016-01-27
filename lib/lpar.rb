require_relative "list"
require_relative "print"

# An LPAR or a host.
class LPAR
  include Print

  # @return [Array<Alert>] Array of {Alert}s that has been added to
  #   the LPAR.
  attr_reader :alerts

  # @return ["Unknown"|Integer] If lparstat.out was parsed, returns
  #   the integer value found of <tt>Online Virtual CPUs</tt>.
  #   Otherwise <tt>Unknown<tt> (a string) is returned.
  attr_reader :cpus

  # @return [String] The hostname as found by the hostname attribute
  #   of the inet0 device.
  attr_reader :hostname

  # @return [String] The id_to_partition as found by the
  #   id_to_partition attribute of the sys0 device.
  attr_reader :id_to_partition

  # @return [String] If lparstat.out was parsed, returns the string
  #   attribute of +Mode+.  Otherwise +Unknown+ is returned.
  attr_reader :smt
  
  # @return [Array<Snap>] A list of {Snap}s that belong to the LPAR.
  attr_accessor :snap_list
  alias snaps snap_list

  # @param db [Db] The database from one of the {Snap}s that belong to
  #   the LPAR being created.
  def initialize(db)
    @hostname = "Unknown"
    @id_to_partition = "Unknown"
    @snap_list = List.new
    @alerts = List.new
    @cpus = "Unknown"
    @smt = "Unknown"
    if devices = db['devices']
      if sys0 = devices['sys0']
        @id_to_partition = sys0.attributes.id_to_partition.value
      end
      if inet0 = devices['inet0']
        @hostname = inet0.attributes.hostname.value
      end
    end
    if lparstat = db['lparstat.out']
      @cpus = lparstat['Online Virtual CPUs'].to_i
      @smt = lparstat['Type']
    end
  end

  # Just syntatic sugar for snaps.each
  def each_snap(&proc)
    snaps.each(&proc)
  end

  # Add an alert to the LPAR.
  # @param text [String] The alert text to add
  def add_alert(text)
    @alerts << Alert.new(text, @db)
  end

  # Compares with the hostname value.
  # @param b [LPAR] The other LPAR to compare to.
  def <=>(b)
    self.hostname <=> b.hostname
  end

  # Marshal out the LPAR as a JSON object
  # @param options [Hash] usual option hash for to_json
  def to_json(options = {})
    {
      alerts:          @alerts,
      hostname:        @hostname,
      id_to_partition: @id_to_partition,
      snaps:           @snaps
    }.to_json(options)
  end
end
