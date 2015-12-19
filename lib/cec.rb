require_relative "list"

# The term CEC is used to denote a set of hardware including the CPU,
# memory, etc.  A CEC may then be divided into virtual LPARs which is
# what is traditionally viewed as a host.  Note that this is *not* a
# subclass of Item.
class CEC
  # @return [String] The id_to_system attribute as pulled from the
  #   sys0 device.
  attr_reader :id_to_system

  # @return [String] The firmware level for the CEC as pulled from the
  #   fwversion attribute of the sys0 device.
  attr_reader :firmware_level

  # @return [String] The model name for CEC as pulled from the
  #   modelname attribute of the sys0 device.
  attr_reader :model

  # @return [String] The CPU type as pulled from the type attribute of
  #   the proc0 device.
  attr_reader :cpu_type

  # @return [Array<Lpar>] The list of {LPAR LPARs} within this CEC.
  attr_reader :lpars

  # @param db [Db] The database from one of the {Snap Snaps} that
  #   belong to the CEC being created.
  def initialize(db)
    @id_to_system = "Unkonwn"
    @firmware_level = "Unknown"
    @model = "Unknown"
    @cpu_type = "Unknown"
    @lpars = List.new
    if devices = db['devices']
      if sys0 = devices['sys0']
        attrs = sys0.attributes
        @id_to_system = attrs.id_to_system.value
        @firmware_level = attrs.fwversion.value.split(',')[1]
        @model = attrs.modelname.value.split(',')[1]
      end
      if proc0 = devices['proc0']
        attrs = proc0.attributes
        @cpu_type = attrs.type.value.sub("PowerPC_", "")
      end
    end
  end

  def <=>(b)
    self.id_to_system <=> b.id_to_system
  end

  def print(context)
    context.output("CEC model:#{model} CPU:#{cpu_type} firmware:#{firmware_level} Id:#{id_to_system}")
    @lpars.print(context.nest)
    context
  end
end
