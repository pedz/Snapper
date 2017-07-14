require_relative 'snapper'
require_relative 'logging'

# This is a file that has snap processor that create alerts if an
# exposure to a fileset that is known to be broken is found.  Rather
#   than look at filesets, we look at the APARs installed.
class BrokenFilesets
  # Add alerts if the snap has filesets that are known to have
  # pervasive issues.
  # @param snap [Snap] the snap to process
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    return unless instfix_i = snap.db.instfix_i
    emgr_snap = snap.db.emgr_snap.to_text
    raise "didn't find instfix_i" if instfix_i.nil?
    raise "didn't find emgr_snap" if emgr_snap.nil?
    $issues.each do |issue|
      inject, relief, text = issue
      next unless $defect2apars[inject].any? { |apar| instfix_i[apar] == 1 }
      next if $defect2apars[relief].any? { |apar| instfix_i[apar] == 1 }
      ifixed = $defect2apars[relief].any? { |apar| Regexp.new(apar).match(emgr_snap) }
      snap.add_alert("#{text} - #{$defect2apars[relief].first}#{ifixed ? " - ifix applied" : ""}")
    end
  end

  Snapper.add_snap_processor(self)
end
