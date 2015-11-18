require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a vlan
# adapter.
class Entstat_vlan < Entstat
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

  # Includes ENT_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Entstat_vlan, "")
