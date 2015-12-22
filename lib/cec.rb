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

  # @return [Array<Lpar>] The list of {LPAR}s within this CEC.
  attr_reader :lpar_list
  alias lpars lpar_list

  # @param db [Db] The database from one of the {Snap}s that belong to
  #   the CEC being created.
  def initialize(db)
    @id_to_system = "Unkonwn"
    @firmware_level = "Unknown"
    @model = "Unknown"
    @cpu_type = "Unknown"
    @lpar_list = List.new
    @alerts = List.new
    @db = db
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

  # Add an alert to the CEC.
  # @param text [String] The alert text to add
  def add_alert(text)
    @alerts << Alert.new(text, @db)
  end

  # Compares with the id_to_system value
  # @param b [CEC] The other CEC to compare to.
  def <=>(b)
    self.id_to_system <=> b.id_to_system
  end

  # Print the CEC out which prints out the info about the CEC along
  # with the list of {Alert}s and {LPAR}s nested one level deeper.
  # @param context [Context] The context to use for printing.
  def print(context)
    context.output("CEC model:#{model} CPU:#{cpu_type} firmware:#{firmware_level} Id:#{id_to_system}")
    @alerts.print(context.nest)
    @lpar_list.print(context.nest)
    context
  end

  # Marshal out the CEC as a JSON object
  # @param options [Hash] usual option hash for to_json
  def to_json(options = {})
    {
      alerts:         @alerts,
      cpu_type:       @cpu_type,
      firmware_level: @firmware_level,
      id_to_system:   @id_to_system,
      lpars:          @lpars,
      model:          @model
    }.to_json(options)
  end
end
