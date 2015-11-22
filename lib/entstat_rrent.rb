require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a rrent
# adapter (Red River / CT3)
class Entstat_rrent < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS, LACP_PRODUCTIONS, and BASE_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Entstat_rrent, "10 Gigabit Ethernet Adapter (ct3)")
