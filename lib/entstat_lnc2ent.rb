require_relative "netstat_v"
require_relative "entstat"
require_relative "entstat_shient.rb"
require_relative "entstat_generic.rb"

# Parsers the output from netstat -d entN where entN is a lnc2ent
# adapter.
class EntstatLnc2ent < Entstat
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  LNC2ENT_PRODUCTIONS =
    [
      PDA::Production.new("PCIe3 4-Port 10GbE SR Adapter") do |md, pda|
      end,

      PDA::Production.new("(?<field>DCBX Status):\\s*(?<value>.*)", [ :normal ], :consumeAll) do |md, pda|
        field = 'unmatched'
        ret = pda.target
        ret[field] = List.new
        ret[field].push(md[0])
      end,
    ]

  # @return [Array<PDA::Production>] {LNC2ENT_PRODUCTIONS},
  #   {ENT_PRODUCTIONS}, {LACP_PRODUCTIONS}, and {BASE_PRODUCTIONS}
  def productions
    LNC2ENT_PRODUCTIONS + EntstatShient::SHIENT_PRODUCTIONS +
      ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS +
      EntstatGeneric::GENERIC_PRODUCTIONS
  end

  # parses the text
  def parse
    super
  end
end

NetstatV::Parsers.instance.add(EntstatLnc2ent, "PCIe3 4-Port 10GbE SR Adapter ")
