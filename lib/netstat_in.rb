require_relative "dot_file_parser"
require_relative "interface"

# Parses the output of netstat -in
class Netstat_in < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  LINK_REGEXP = Regexp.new("link#[0-9]+")
  INET_REGEXP = Regexp.new("([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)")
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
end
