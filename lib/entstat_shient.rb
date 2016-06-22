require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a shient
# adapter.
class EntstatShient < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  SHIENT_PRODUCTIONS =
    [
      # Sample Match:   |Enabled VLAN IDs:
      # States Matched: :normal
      # New State:      :shiVLANIds
      # State Pushed:   none
      # States Popped:  0
      # This attribute comes in two flavors.  Usually it is
      # "Enabled VLAN IDs: None" which is consume be the rules below.
      # The other flavor is a list of VLAN IDs.  I don't know if they
      # are listed one per line since I've never seen such output.
      # I've only seen a single vlan id listed on the nextl line
      PDA::Production.new("^(?<field>Enabled VLAN IDs):$", [:normal], :shiVLANIds) do |md, pda|
        field = md[:field].strip
        value = []
        pda.target[field] = value
        pda.push(value)
      end,

      # Sample Match:   |	0148
      # States Matched: :shiVLANIds
      # New State:      :no_change
      # State Pushed:   none
      # States Popped:  0
      # Parse the list of vlan ids
      # Whatever we do must be in place.  e.g. += does not work
      # because it creates a new object and breaks the link from the
      # "Enabled VLAN IDs" field
      PDA::Production.new("^(?<values>[^:\n]+)$", [:shiVLANIds]) do |md, pda|
        md[:values].split.each { |v| pda.target.push(v.to_i(10)) }
      end,

      # Sample Match:   |PCIe2 4-Port Adapter (10GbE SFP+) (e4148a1614109304)
      # States Matched: :normal
      # New State:      :no_change
      # State Pushed:   none
      # States Popped:  0
      # Ignored
      PDA::Production.new("^PCIe2 4-Port Adapter \\(1GbE RJ45\\) \\(e4148a1614109404\\)|PCIe2 4-Port Adapter \\(10GbE SFP\\+\\) \\(e4148a1614109304\\)", [:normal]) do |md, pda|
      end,

      # Sample Match:   |Assigned Interrupt Source Numbers: 
      # States Matched: :normal
      # New State:      :no_change
      # State Pushed:   :shiInterrupts
      # States Popped:  0
      # Start of a list of interrupt source numbers
      PDA::Production.new("^(?<field>Assigned Interrupt Source Numbers):\\s*", [:normal], :shiInterrupts) do |md, pda|
        field = md[:field].strip
        value = WriteOnceHash.new
        pda.target[field] = value
        pda.push(value)
      end,

      # Sample Match:   |	15344	MGT
      # States Matched: :shiInterrupts
      # New State:      :no_change
      # State Pushed:   none
      # States Popped:  0
      # The interrupt source number and some name that goes with it.
      PDA::Production.new("^\\s*(?<left>[0-9]+)\\s*(?<right>\\S.*\\S)\\s*$", [:shiInterrupts]) do |md, pda|
        left = md[:left]
        right = md[:right]
        pda.target[left] = right
      end,

      # Sample Match:   |Receive statistics for RXQ number: 2
      # States Matched: :normal and :shientQStats
      # New State:      :shientQStats
      # State Pushed:   yes
      # States Popped:  1 if already in :shientQStats state
      # This starts a new group so subsequent fields are added into
      # (for example) "Transmit Q0 Statistics"
      PDA::Production.new("^(?<field>(Receive|Transmit) Q[0-9]+ Statistics):\\s*$", [:normal, :shientQStats], :shientQStats) do |md, pda|
        field = md[:field]
        value = WriteOnceHash.new
        pda.pop(1) unless pda.state == :normal
        ret = pda.target
        ret[field] = value
        logger.debug { "Starting #{field}" }
        pda.push(value)
      end,
      
      # Sample Match:   |Adapter Reset Count: 0
      # States Matched: :all
      # New State:      :no_change
      # State Pushed:   none
      # States Popped:  0
      # For lines with exactly one colon and the value is an integer.
      # Leading white space is allowed.  Text before colon is
      # md[:field].  Text after colon is md[:value].  Leading and
      # trailing white space from both are stripped.  Value can not
      # be empty and is converted to an integer.
      # Needed because the rule in BASE is only for state of normal
      PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>-?\\d+)\\s*$", [:shientQStats]) do |md, pda|
        field = md[:field].strip
        value = md[:value].to_i
        pda.target[field] = value
      end,
      
      # Sample Match:   |	[q-0]: rx_bytes:	0
      # States Matched: :all
      # New State:      :no_change
      # State Pushed:   none
      # States Popped:  0
      # Creates an entry called "q" which is an array starting at 0, of
      # write once hashes.
      PDA::Production.new("^\\s*\\[q-(?<index>[0-9]+)\\]:\\s*(?<field>[^: ][^:]*):\\s+(?<value>[0-9]+)\\s*$") do |md, pda|
        index = md[:index].to_i
        field = md[:field].strip
        value = md[:value].to_i
        target = pda.target
        target["q"] = List.new unless target.has_key?("q")
        q = target["q"]
        q[index] = WriteOnceHash.new unless q[index]
        q[index][field] = value
      end
    ]

  # @return [Array<PDA::Production>] {SHIENT_PRODUCTIONS},
  #   {ENT_PRODUCTIONS}, {LACP_PRODUCTIONS}, and {BASE_PRODUCTIONS}
  def productions
    SHIENT_PRODUCTIONS + ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end

  # parses the text
  def parse
    super
  end
end

NetstatV::Parsers.instance.add(EntstatShient, "PCIe2 4-Port Adapter (10GbE SFP+) (e4148a1614109304)")
NetstatV::Parsers.instance.add(EntstatShient, "PCIe2 4-Port Adapter (1GbE RJ45) (e4148a1614109404)")
