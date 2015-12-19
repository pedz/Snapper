require_relative 'logging'
require_relative 'list'
require_relative 'cec'
require_relative 'lpar'
require_relative 'snap'

# A container for a list of {Snap Snaps} and {Alert Alerts}.  This
# concept may go away eventually because once the snaps are parsed,
# they will get put into groups by CEC ({Snap#id_to_system
# id_to_system}) and then by LPAR ({Snap#hostname hostname}).
class Batch
  # @return [Array<Snap>] The list of {Snap Snaps} passed in via new.
  attr_reader :snap_list

  # Passed a list of snaps
  # @param snap_list [Array<Snap>] A list of {Snap Snaps}.
  def initialize(snap_list)
    @snap_list = snap_list
    @alerts = List.new
  end

  # Add an alert
  def add_alert(alert)
    @alerts << alert
  end

  def print(context)
    @alerts.each do |alert|
      alert.print(context)
    end

    # I don't know really where to put thsi code yet.
    @cecs ||= @snap_list.group_by(&:id_to_system).map do |id, list|
      cec = CEC.new(list[0].db)
      lpars = list.group_by(&:hostname).map do |id, snaps|
        lpar = LPAR.new(snaps[0].db)
        lpar.snaps.push(*snaps.sort)
        lpar
      end
      cec.lpars.push(*lpars.sort)
      cec
    end.sort
    @cecs.print(context)
  end

  def to_json(options = {})
    {
      snap_list: @snap_list,
      alerts: @alerts
    }.to_json(options)
  end
end
