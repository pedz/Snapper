require_relative "item"

# A class created by Interfaces.  Currently only information from
# netstat -in is added but information from ifconfig -a will be add in
# eventually.
#
# The current list of fields is:
#
# [:mtu]   The MTU of the interface
#
# [:mac]   The MAC of the interface
#
# [:ipkts] The number of incoming packets.
#
# [:ierrs] The number of incoming errors.
#
# [:opkts] The number of outgoing packets.
#
# [:oerrs] The number of outgoing errors.
#
# [:coll]  The number of collisions (obsolete)
#
# [:addrs] A list of addresses
#
#          [:family] Currently either :ipv4 or :ipv6
#
#          [:address] The address
#
#          [:network] The address of the network (after the netmask
#                     has been applied).
#
class Interface < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def initialize(*args)
    super
    self[:addrs] = List.new
  end

  def pretty_addr(index)
    return "" if index >= self[:addrs].length
    addr = self[:addrs][index]
    s = addr[:address]
    s += "/#{addr[:netmask_length]}" if addr.has_key?(:netmask_length)
    return s
  end
end
