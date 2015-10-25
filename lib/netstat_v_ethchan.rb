require_relative "netstat_v"

# Parsers the output from netstat -d entN where entN is a ethchan
# adapter.
class Netstat_v_ethchan < Netstat_v::Base
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

  # Includes ENT_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_ethchan, "EtherChannel")
Netstat_v::Parsers.instance.add(Netstat_v_ethchan, "IEEE 802.3ad Link Aggregation")
