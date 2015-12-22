require_relative "dot_file_parser"
require_relative "interface"

# Parses the output of <tt>netstat -in</tt>
class Netstat_in < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # A Regexp pattern that matches the "link line" (line #1 below).
  LINK_REGEXP = Regexp.new("link#[0-9]+")

  # A Regexp patter that matches an IPv4 address
  INET_REGEXP = Regexp.new("([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)")

  # For reference, there are two types of lines in the netstat -in
  # output as shown below
  #   1.  en9   1500  link#2      0.0.c9.d9.e8.bf         0     0       14     0     0
  #   2.  en9   1500  10.201.10   10.201.10.31            0     0       14     0     0
  # Parses the lines and creates entries in the Netstat_in with keys
  # of the interface name (e.g. en9 or lo0).  Each entry is an
  # Interface whose keys are described there.
  def parse
    headings = nil
    @text.each_line do |line|
      line.chomp!
      next if line.empty?
      if headings.nil?
        # I ended up no uses the headings.
        headings = line.split
      else
        fields = line.split
        name = fields.shift
        record = (self[name] ||= Interface.new("", { name: name }, @db))
        if fields.length == 8
          mtu, network, address, ipkts, ierrs, opkts, oerrs, coll = fields
        else
          mtu, network, ipkts, ierrs, opkts, oerrs, coll = fields
          address = ""
        end
        if LINK_REGEXP.match(network)
          record[:mtu] = mtu.to_i
          record[:mac] = address
          record[:ipkts] = ipkts.to_i
          record[:ierrs] = ierrs.to_i
          record[:opkts] = opkts.to_i
          record[:oerrs] = oerrs.to_i
          record[:coll] = coll.to_i
        elsif INET_REGEXP.match(address)
          (record[:inet] ||= List.new).push({ network: network, address: address })
          else
          (record[:inet6] ||= List.new).push({ network: network, address: address })
        end
      end
    end
    self
  end
  # @param  remove me
end
