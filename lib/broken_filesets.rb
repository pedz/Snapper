require_relative 'snapper'
require_relative 'logging'
require_relative 'devices'

# This is a file that has snap processor that create alerts if an
# exposure to a fileset that is known to be broken is found.  Rather
#   than look at filesets, we look at the APARs installed.
class BrokenFilesets
  
  # Add alerts if the snap has filesets that are known to have
  # pervasive issues.
  # @param snap [Snap] the snap to process
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    @instfix_i = snap.db['instfix_i']
    @instfix_out = snap.db['instfix.out']
    emgr_snap = snap.db['emgr_snap']
    emgr_snap = emgr_snap.to_text if emgr_snap
    emgr_snap ||= ""
    return if @instfix_i.nil? && @instfix_out.nil?

    @issues.each do |issue|
      inject, relief, text, proc = issue
      next unless inject == "true" || @defect2apars[inject].any? { |apar| has_fix(apar) }
      next if @defect2apars[relief].any? { |apar| has_fix(apar) }
      next unless proc.call(snap)
      ifixed = @defect2apars[relief].any? { |apar| Regexp.new(apar).match(emgr_snap) }
      snap.add_alert("#{text} - #{relief} (#{@defect2apars[relief].first})#{ifixed ? " - ifix applied" : ""}")
    end
  end

  private

  DOWN_LEVEL = "-"
  CORRECT_LEVEL = "="
  SUPERSEDED = "+"
  NOT_INSTALLED = "!"

  def self.has_fix(apar)
    return @instfix_i[apar] == 1 unless @instfix_i.nil?
    return false unless fix = @instfix_out[apar]
    return fix[:status] == CORRECT_LEVEL || fix[:status] == SUPERSEDED
  end

  def self.dev_with(snap, driver)
    snap.db.devices.any? { |name, device| device.cu_dv.ddins == driver }
  end
  
  Snapper.add_snap_processor(self)
end
