require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a rrent
# adapter (Red River / CT3)
class EntstatRrent < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # (see EntstatGoent#productions)
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end

  # parses the text
  def parse
    super
  end
end

NetstatV::Parsers.instance.add(EntstatRrent, "10 Gigabit Ethernet Adapter (ct3)")
