require "spec_helper"
require "ifconfig_a"

describe IfconfigA do
  describe "#parse" do
    before(:context) {
      text = <<'EOF'

en0: flags=1e084867,14c0<UP,BROADCAST,DEBUG,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),LARGESEND,CHAIN>
        inet 10.174.149.8 netmask 0xfffffc00 broadcast 10.174.151.255
        inet 10.174.149.7 netmask 0xfffffc00 broadcast 10.174.151.255
         tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
en1: flags=1e084863,14c0<UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),LARGESEND,CHAIN>
        inet 10.119.23.76 netmask 0xffffff00 broadcast 10.119.23.255
        inet 10.119.23.78 netmask 0xfffffc00 broadcast 10.119.23.255
         tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
lo0: flags=e08084b,c0<UP,BROADCAST,LOOPBACK,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,LARGESEND,CHAIN>
        inet 127.0.0.1 netmask 0xff000000 broadcast 127.255.255.255
        inet6 ::1%1/0
         tcp_sendspace 131072 tcp_recvspace 131072 rfc1323 1

EOF
      @result = IfconfigA.new(text, Hash.new).parse
    }

    it "parses and makes an entry for each interface" do
      expect(@result.length).to eq(3)
    end
  end
end
