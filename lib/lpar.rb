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

  # @return [String] The type of partition which may be "Dedicated" or
  # "Shared".  +type+ may not be a good term for this attribute.
  attr_accessor :type
  
  # @param db [Db] The database from one of the {Snap}s that belong to
  #   the LPAR being created.
  def initialize(db)
    @hostname = "Unknown"
    @id_to_partition = "Unknown"
    @snap_list = List.new
    @alerts = List.new
    @cpus = "Unknown"
    @smt = "Unknown"
    proc0 = nil
    if devices = db['devices']
      if sys0 = devices['sys0']
        @id_to_partition = sys0.attrs.id_to_partition
      end
      if inet0 = devices['inet0']
        @hostname = inet0.attrs.hostname
      end
      proc0 = devices['proc0']
    end
    if lparstat = db['lparstat.out']
      @cpus = lparstat['Online Virtual CPUs'].to_i

      # "Type" from lparstat.out comes in a few forms:
      #  1. Dedicated-SMT
      #  1. Dedicated-SMT-4
      #  1. Shared-SMT
      #  1. Shared-SMT-4
      if type_temp = lparstat['Type']
        type_temp = type_temp.split('-')
        @type = type_temp[0]

        # The lparstat.out file does not always have the number of SMT
        # threads.  So, lets trust proc0 and if that fails, lets use
        # what lparstat says
        if proc0
          if proc0.attrs['smt_enabled'] == "true"
            @smt = proc0.attrs['smt_threads'].to_i
          else
            @smt = 1
          end
        else
          @smt = type_temp[2] || "??"
        end
      end
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
