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
      next unless inject == "true" || @defect2apars[inject].any? { |apar| has_fix(apar, 0) }
      next if @defect2apars[relief].any? { |apar| has_fix(apar, 1) }
      next unless proc.call(snap)
      ifixed = @defect2apars[relief].any? { |apar| Regexp.new(apar).match(emgr_snap) }
      snap.add_alert("#{text} - #{relief} (#{@defect2apars[relief].first})#{ifixed ? " - ifix applied" : ""}")
    end

    other_stuff(snap, options)
  end

  private

  # I have not split this off to another class...
  def self.other_stuff(snap, options)
    hits = 0
    if lslpp_lc = snap.db['lslpp -lc']
      [ "ds_agent.rte" ].each do |fs|
        if lslpp_lc[fs]
          snap.add_alert("#{fs} is installed") if options.level > 3
          hits += 1
        end
      end
    end
    if inittab = snap.db['inittab']
      inittab.each do |inittab|
        [ "ds_filter", "ds_agent" ].each do |name|
          if inittab[:name] == name
            snap.add_alert("#{name} is in inittab") if options.level > 3
            hits += 1
          end
        end
      end
    end
    snap.add_alert("Trend Micro is installed") if hits > 0 && options.level <= 3
  end

  DOWN_LEVEL = "-"
  CORRECT_LEVEL = "="
  SUPERSEDED = "+"
  NOT_INSTALLED = "!"

  def self.has_fix(apar, value)
    return @instfix_i[apar] && @instfix_i[apar] >= value unless @instfix_i.nil?
    return false unless fix = @instfix_out[apar]
    return fix[:status] == CORRECT_LEVEL || fix[:status] == SUPERSEDED
  end

  def self.dev_with(snap, driver)
    snap.db.devices.any? { |name, device| device.cu_dv.ddins == driver }
  end
  
  ENTCORE_DRIVERS = [
    'pci/lnc2entdd',
    'pci/mlxentdd',
    'pci/mlxcentdd',
    'pci/shientdd'
  ]
                      
  def self.sea_with_entcore(snap)
    dev_with(snap, 'seadd') &&
      ENTCORE_DRIVERS.any? { |dvr| dev_with(snap, dvr) }
  end

  Snapper.add_snap_processor(self)
end
