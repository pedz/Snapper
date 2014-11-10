require_relative "netstat_v"

# Parsers the output from netstat -d entN where entN is a musent
# adapter.
class Netstat_v_musent < Netstat_v::Base
  include Logging
  # The log level that Netstat_v_musent uses:
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS and productions to put the RXQ and TXQ
  # statistics into their own hashes index by the queue number.
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_musent, "Gigabit Ethernet PCIe Adapter (e4145716e4142004)")
