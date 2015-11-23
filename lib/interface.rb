require_relative "item"

# A class created by Interfaces.  Currently only information from
# netstat -in is added but information from ifconfig -a will be add in
# eventually.
#
# The current list of fields is:
# [:mtu]   The MTU of the interface
# [:mac]   The MAC of the interface
# [:ipkts] The number of incoming packets.
# [:ierrs] The number of incoming errors.
# [:opkts] The number of outgoing packets.
# [:oerrs] The number of outgoing errors.
# [:coll]  The number of collisions (obsolete)
# [:inet]  A list of addresses with two fields in each address:
#          [:address] The IPv4 address
#          [:network] The address of the network (after the netmask
#                     has been applied).
# [:inet6] A similar list as :inet exept containts IPv6 addresses.
class Interface < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
