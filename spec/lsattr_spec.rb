require "spec_helper"
require "lsattr"
require "db"

describe Lsattr do
  before(:context) do
    @db = Db.new
    @text = <<'HERE'
alias4             IPv4 Alias including Subnet Mask              True
alias6             IPv6 Alias including Prefix Length            True
arp           on   Address Resolution Protocol (ARP)             True
authority          Authorized Users                              True
broadcast          Broadcast Address                             True
monitor       off  Enable/Disable monitor attribute              True
mtu           1500 Maximum IP Packet Size for This Device        True
mtu_bypass    off  Enable/Disable largesend for virtual Ethernet True
netaddr            Internet Address                              True
netaddr6           IPv6 Internet Address                         True
netmask            Subnet Mask                                   True
prefixlen          Prefix Length for IPv6 Internet Address       True
remmtu        576  Maximum IP Packet Size for REMOTE Networks    True
rfc1323            Enable/Disable TCP RFC 1323 Window Scaling    True
security      none Security Level                                True
state         down Current Interface Status                      True
tcp_mssdflt        Set TCP Maximum Segment Size                  True
tcp_nodelay        Enable/Disable TCP_NODELAY Option             True
tcp_recvspace      Set Socket Buffer Space for Receiving         True
tcp_sendspace      Set Socket Buffer Space for Sending           True
thread        off  Enable/Disable thread attribute               True
HERE
    @item = @db.create_item("lsattr_elfoo", @text)
    @devices = @db.create_item("devices")
    @devices['foo'] = Item.new(@db)
    @snap = Snap.new({ dir: "blah", db: @db})
    Lsattr.process_snap(@snap)
    @lsattrs = @db.lsattrs
    @lsattr = @lsattrs.lsattr_elfoo
  end

  it "should replace the lsattr_elfoo entry with an lsattr entry" do
    expect(@lsattr.class).to eq(Lsattr)
  end

  it "should add an 'lsattr' property to the logical device" do
    expect(@devices['foo']['lsattr'].class).to eq(Lsattr)
  end

  it "should parse the 'alias4' attribute as being null" do
    expect(@lsattr.alias4.value).to be nil
  end

  it "should parse the 'mtu' attribute as being 1500" do
    expect(@lsattr.mtu.value).to eq(1500)
  end
end
