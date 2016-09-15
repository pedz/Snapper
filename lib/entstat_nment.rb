require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a nment
# adapter.
class EntstatNment < Entstat
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO      # The log level the NetstatV uses.

  QLOGIC_PRODUCTIONS =
    [
      # Sample Match:   |Qlogic combo Gigabit Ethernet PCI-Express Adapter (e4143a161410a003) 
      # States Matched: :normal
      # New State:      :no_change
      # State Pushed:   none
      # States Popped:  0
      # The Device Type is on the next line.
      PDA::Production.new("(?<value>^Qlogic combo Gigabit Ethernet PCI-Express Adapter \\(\\h+\\) $)", [:normal]) do |md, pda|
        value = md[:value].strip
        field = "Device Type"
        ret = pda.target
        ret[field] = value
      end
    ]

  # @return [Array<PDA::Production>] {ENT_PRODUCTIONS},
  #   {LACP_PRODUCTIONS}, and {BASE_PRODUCTIONS}.
  def productions
    QLOGIC_PRODUCTIONS + ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end

  # parses the text
  def parse
    super
  end
end

NetstatV::Parsers.instance.add(EntstatNment, "Qlogic combo Gigabit Ethernet PCI-Express Adapter (e4143a161410a003) ")
