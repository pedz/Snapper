require "spec_helper"
require "netstat_v_vlan"

describe Netstat_v_vlan do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent13) :
Device Type: 
Hardware Address: e4:1f:13:d8:28:c4
Elapsed Time: 0 days 19 hours 55 minutes 41 seconds

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 600602                               Packets: 563761
Bytes: 63284179                               Bytes: 57750627
Interrupts: 0                                 Interrupts: 516610
Transmit Errors: 0                            Receive Errors: 116277
Packets Dropped: 0                            Packets Dropped: 2288
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 48        
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Elapsed Time: 0 days 0 hours 0 minutes 0 seconds
Broadcast Packets: 89419                      Broadcast Packets: 41908
Multicast Packets: 275122                     Multicast Packets: 212340
No Carrier Sense: 0                           CRC Errors: 0
DMA Underrun: 0                               DMA Overrun: 0
Lost CTS Errors: 0                            Alignment Errors: 0
Max Collision Errors: 0                       No Resource Errors: 0
Late Collision Errors: 0                      Receive Collision Errors: 0
Deferred: 0                                   Packet Too Short Errors: 3
SQE Test: 0                                   Packet Too Long Errors: 0
Timeout Errors: 0                             Packets Discarded by Adapter: 116274
Single Collision Count: 0                     Receiver Start Count: 0
Multiple Collision Count: 0
Current HW Transmit Queue Length: 0

General Statistics:
-------------------
No mbuf Errors: 0
Adapter Reset Count: 0
Adapter Data Rate: 0
Driver Flags: Up Broadcast Running 
	Simplex 64BitSupport ChecksumOffload 
	DataRateSet 

EOF
    @result = Netstat_v.new(text).result["ent13"]
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("e4:1f:13:d8:28:c4")
  end
  it "parsers the transmit packets as an integer" do
    expect(@result["Transmit Statistics"]["Packets"]).to eq(600602)
  end
  it "parsers the receive bytes as an integer" do
    expect(@result["Receive Statistics"]["Bytes"]).to eq(57750627)
  end
  it "parses the Driver Flags as an array of strings" do
    expect(@result["Driver Flags"]).to eq(["Up", "Broadcast", "Running",
                                         "Simplex", "64BitSupport",
                                         "ChecksumOffload",
                                         "DataRateSet"])
  end
  it "parses 'Current HW Transmit Queue Length' under the Transmit Statistics" do
    expect(@result["Transmit Statistics"]["Current HW Transmit Queue Length"]).to eq(0)
  end
end
