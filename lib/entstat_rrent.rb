require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a rrent
# adapter.
class Entstat_rrent < Entstat
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

  # Includes ENT_PRODUCTIONS as well as SEA specific productions.
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Entstat_rrent, "10 Gigabit Ethernet Adapter (ct3)")
