require_relative "netstat_v"
require "stringio"

# Parsers the output from netstat -d entN where entN is a goent
# adapter.
class Netstat_v_goent < Netstat_v::Base
  include Logging
  # The log level the Netstat_v uses.
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS
  def productions
    ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_goent, "4-Port 10/100/1000 Base-TX PCI-Express Adapter (14106803)")
