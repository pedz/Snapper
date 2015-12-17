require_relative 'logging'
require_relative 'list'

# A container for a list of Snaps[Snap.html] and Alerts[Alert.html]
class Batch
  # The Db database passed
  attr_reader :snap_list

  # Passed a list of snaps
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
