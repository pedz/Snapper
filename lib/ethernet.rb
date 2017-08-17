require_relative 'device'
require_relative 'logging'

class Ethernet < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def description(context)
    attrs = [ cu_dv.name, cu_dv.ddins ]
    if entstat = self.entstat
      # There are various place where the bit rate of the link is
      # hidden.  Most common is Adapter Data Rate but it is twice the
      # bit rate because everything today is full duplex so a 10G will
      # say 20000
      speed = 0
      speed = entstat['adapter_data_rate'] / 2 if entstat['adapter_data_rate']

      # Some output has Physical Data Rate: but it is text and
      # includes things like Unknown and Auto-negotiation.  The other
      # choices are formatted like 40Gbs Full Duplex.  Awkward, at
      # best, to parse
      #
      # There is also Media Speed Running: which has similar
      # difficulties with Unknown, Autonegotiate, and (e.g.) 10000
      # Mpbs / 10 Gbps, Full Duplex -- whew! what a mouthful!
      if md = SPEED_REGEXP.match(entstat.to_text)
        speed = md[:speed].to_i * 1000
      end

      attrs.push((speed >= 1000) ? "#{speed / 1000}G" : "#{speed}M") if speed > 0

      # We get driver flags and convert them to attributes
      attrs += entstat.driver_flags.map { |flag| TEXT_MAP[flag] }
      attrs.delete(nil)
    end
    attrs.push("MAC:#{entstat.hardware_address}") if entstat['hardware_address']
    attrs.push(context.modifier)
    return attrs.join(' ')
  end

  private

  SPEED_REGEXP = / (?<speed>[1-9][0-9]*) *gbps/im
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
