require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a vlan
# adapter.
class Entstat_vlan < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS, LACP_PRODUCTIONS, and BASE_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Entstat_vlan, "")
