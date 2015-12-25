require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a vlan
# adapter.
class EntstatVlan < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # (see EntstatGoent#productions)
  def productions
    ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
  # @param  remove me
end

NetstatV::Parsers.instance.add(EntstatVlan, "")
