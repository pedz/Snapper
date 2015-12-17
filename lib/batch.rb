require_relative 'logging'
require_relative 'list'

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

    cecs = @snap_list.group_by { |snap| snap.id_to_system }
    cecs.each_pair do |key, list|
      cecs[key] = list.group_by { |snap| snap.hostname }
    end
    nested = context.nest
    cecs.keys.sort.each do |id_to_system|
      context.output("Id to System: #{id_to_system}")
      cec = cecs[id_to_system]
      cec.keys.sort.each do |hostname|
        cec[hostname].each do |snap|
          nested.output("Host: #{hostname}")
          snap.print(nested.nest)
        end
      end
    end
    # @snap_list.each do |snap|
    #   snap.print(context)
    # end
  end

  def to_json(options = {})
    {
      snap_list: @snap_list,
      alerts: @alerts
    }.to_json(options)
  end
end
