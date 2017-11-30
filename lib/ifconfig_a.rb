require_relative "dot_file_parser"

# Parses the <tt>ifconfig -a</tt> output found in +tcpip/tcpip.snap+.
class IfconfigA < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  OUTER_REGEXP = /^([a-z][a-z][0-9]+):/
  FLAGS_REGEXP = /\A\s*flags=([0-9a-f]+),([0-9a-f]+)<([^>]*)>\s*\Z/
  INET_REGEXP = /\A\s*inet ([0-9.]+) netmask ([0-9a-fx]+) broadcast ([0-9.]+)\s*\Z/
  INET6_REGEXP = /\A\s*inet6 ([0-9:%\/]+)\s*\Z/

  # self will be an Item with keys equal to the interface names
  # (e.g. en0 or lo0).  The values will be a hash with keys:
  #   :flags - An array of two Fixnums for the flags
  #   :flag_syms - An array of strings such as "UP", "RUNNING", etc
  #   :addr - array of hashes for each addresses with keys:
  #     :ipv4 - the IPv4 address as a string (e.g. "10.1.1.20")
  #     :ipv4_bytes - the IPv4 address as an array of four Fixnums
  #     :netmask - the IPv4 netmask as a Fixnum
  #     :netmask_length - the IPv4 netmask as a Fixnum bit length --
  #       e.g. if netmask is 0xffffff00 then :mask_length will be 24
  #     :broadcast - The broadcast address as a string
  #     :broadcast_bytes - The broadcast address as an array of four
  #       Fixnums
  #     :ipv6 - The IPv6 address as a string
  def parse
    _blank_lines, *interfaces = @text.split(OUTER_REGEXP)
    Hash[*interfaces].each_pair do |name, value|
      flags, *lines = value.split("\n")
      record = (self[name] ||= Interface.new("", { name: name }, @db))
      if md = FLAGS_REGEXP.match(flags)
        record[:flags] = [ md[1].hex, md[2].hex ]
        record[:flag_syms] = md[3].split(',')
      end
      lines.each do |line|
        if md = INET_REGEXP.match(line)
          addr = {}
          addr[:family] = :ipv4
          addr[:address] = md[1]
          addr[:netmask] = md[2].hex
          addr[:netmask_length] = 32
          addr[:broadcast] = md[3]
          (1 .. 32).each do |i|
            if addr[:netmask] & (1 << (31 - i)) == 0
              addr[:netmask_length] = i
              break
            end
          end
          record[:addrs].push(addr)
        elsif md = INET6_REGEXP.match(line)
          addr = {}
          addr[:family] = :ipv6
          addr[:address], addr[:netmask_length] = md[1].split('/')
          record[:addrs].push(addr)
        end
      end
    end
    self
  end
end
