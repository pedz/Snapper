require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a goent
# adapter.
class Entstat_goent < Entstat
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

  # Includes ENT_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Entstat_goent, "4-Port 10/100/1000 Base-TX PCI-Express Adapter (14106803)")
