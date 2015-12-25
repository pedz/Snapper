require_relative 'logging'
require_relative 'list'
require_relative 'cec'
require_relative 'lpar'
require_relative 'snap'

# A container for a list of {Snap}s and {Alert}s.  This concept may go
# away eventually because once the snaps are parsed, they will get put
# into groups by CEC ({Snap#id_to_system id_to_system}) and then by
# LPAR ({Snap#hostname hostname}).
class Batch
  # @return [Array<CEC>] The list of known {CEC}s.
  attr_reader :cec_list
  alias cecs cec_list

  # Passed a list of snaps
  # @param snap_list [Array<Snap>] A list of {Snap}s.
  def initialize(snap_list)
    @snap_list = snap_list
    @alerts = List.new
    @cec_list = @snap_list.group_by(&:id_to_system).map do |id, list|
      cec = CEC.new(list[0].db)
      lpars = list.group_by(&:hostname).map do |id, snaps|
        lpar = LPAR.new(snaps[0].db)
        lpar.snaps.push(*snaps.sort)
        lpar
      end
      cec.lpars.push(*lpars.sort)
      cec
    end.sort
  end

  # Just syntatic sugar for cecs.each
  def each_cec(&proc)
    cecs.each(&proc)
  end

  # Add an alert
  # @param text [String] The alert text to add
  def add_alert(text)
    @alerts << Alert.new(text, @db)
  end

  # Print out the batch.
  # @param context [Context] The context to use for printing, etc.
  def print(context)
    @alerts.print(context)
    @cec_list.print(context)
    context
  end

  # Currently we dump out the snap_list and not the cec_list
  # @param options [Hash] The normal to_json options.
  def to_json(options = {})
    {
      snap_list: @snap_list,
      alerts: @alerts
    }.to_json(options)
  end
end
