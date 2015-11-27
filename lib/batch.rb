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

  def print(options)
    @alerts.each do |alert|
      alert.print(options)
    end

    @snap_list.each do |snap|
      snap.print(options)
    end
  end

  def to_json(options = {})
    {
      snap_list: @snap_list,
      alerts: @alerts
    }.to_json(options)
  end
end
