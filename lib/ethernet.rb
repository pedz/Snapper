require_relative 'device'
require_relative 'logging'

class Ethernet < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def description(context)
    attrs = [ cu_dv.name, cu_dv.ddins ]
    if entstat = self.entstat
      attrs += entstat.driver_flags.map { |flag| TEXT_MAP[flag] }
      attrs.delete(nil)
    end
    attrs.push(context.modifier)
    return attrs.join(' ')
  end

  private

  TEXT_MAP = {
    # "64BitSupport" =>     "",
    # "AllMulticast" =>     "",
    "AlternateAddress" => "AA",
    # "Broadcast" =>        "",
    "ChecksumOffload" =>  "C4",
    # "DataRateSet" =>      "",
    "Dead" =>             "DEAD",
    # "Debug" =>            "",
    # "ETHERCHANNEL" =>     "",
    "IPV6_CSO" =>         "C6",
    "IPV6_LSO" =>         "L6",
    "LARGE_RECEIVE" =>    "LR",
    "LargeSend" =>        "L4",
    "Limbo" =>            "LIMBO",
    # "PHYS_LINK_UP" =>     "",
    # "PrivateSegment" =>   "",
    "Promiscuous" =>      "PM",
    # "Running" =>          "",
    # "Simplex" =>          "",
    # "Up" =>               "",
    # "VIOENT" =>           "",
    "VIRTUAL_PORT" =>     "VF"
  }
end
