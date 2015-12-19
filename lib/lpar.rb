require_relative "list"

# An LPAR or a host.
class LPAR
  # @return [String] The hostname as found by the hostname attribute
  #   of the inet0 device.
  attr_reader :hostname

  # @return [String] The id_to_partition as found by the
  # id_to_partition attribute of the sys0 device.
  attr_reader :id_to_partition
  
  # @return [Array<Snap>] A list of {Snap Snaps} that belong to the
  # LPAR.
  attr_accessor :snaps

  # @param db [Db] The database from one of the {Snap Snaps} that
  #   belong to the LPAR being created.
  def initialize(db)
    @hostname = "Unknown"
    @id_to_partition = "Unknown"
    @snaps = List.new
    if devices = db['devices']
      if sys0 = devices['sys0']
        @id_to_partition = sys0.attributes.id_to_partition.value
      end
      if inet0 = devices['inet0']
        @hostname = inet0.attributes.hostname.value
      end
    end
  end

  def <=>(b)
    self.hostname <=> b.hostname
  end

  def print(context)
    context.output("Host: #{hostname}")
    @snaps.print(context.nest)
    context
  end
end
