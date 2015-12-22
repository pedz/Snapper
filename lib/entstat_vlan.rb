require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a vlan
# adapter.
class Entstat_vlan < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # (see Entstat_goent#productions)
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
  # @param  remove me
end

Netstat_v::Parsers.instance.add(Entstat_vlan, "")
