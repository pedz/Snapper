require_relative "netstat_v"

# Parsers the output from netstat -d entN where entN is a vlan
# adapter.
class Netstat_v_vlan < Netstat_v::Base
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

  # Includes ENT_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_vlan, "")
