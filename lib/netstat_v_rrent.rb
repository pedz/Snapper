require_relative "netstat_v"

# Parsers the output from netstat -d entN where entN is a rrent
# adapter.
class Netstat_v_rrent < Netstat_v::Base
  include Logging
  # The log level the Netstat_v uses.
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS as well as SEA specific productions.
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_rrent, "10 Gigabit Ethernet Adapter (ct3)")
