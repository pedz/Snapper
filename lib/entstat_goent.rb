require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a goent
# adapter.
class EntstatGoent < Entstat
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO      # The log level the NetstatV uses.

  # @return [Array<PDA::Production>] {ENT_PRODUCTIONS},
  #   {LACP_PRODUCTIONS}, and {BASE_PRODUCTIONS}.
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
  # @param  remove me
end

NetstatV::Parsers.instance.add(EntstatGoent, "4-Port 10/100/1000 Base-TX PCI-Express Adapter (14106803)")
