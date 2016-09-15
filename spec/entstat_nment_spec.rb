require "spec_helper"
require "entstat_nment"

describe EntstatNment do 
  describe "#parse" do
    before(:context) {
      text = <<EOF
ETHERNET STATISTICS (ent2) :
Device Type: 
Qlogic combo Gigabit Ethernet PCI-Express Adapter (e4143a161410a003) 
Hardware Address: e4:1f:13:90:8f:f4

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 519793740                            Packets: 937978920
Bytes: 556893056448                           Bytes: 423501173436
Interrupts: 0                                 Interrupts: 14819093778
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 18654                        Packets Dropped: 0
                                              Bad Packets: 0

Max Packets on S/W Transmit Queue: 1613      
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 1

Broadcast Packets: 8741                       Broadcast Packets: 417183245
Multicast Packets: 8                          Multicast Packets: 124106624
No Carrier Sense: 0                           CRC Errors: 0
DMA Underrun: 0                               DMA Overrun: 0
Lost CTS Errors: 0                            Alignment Errors: 0
Max Collision Errors: 0                       No Resource Errors: 0
Late Collision Errors: 0                      Receive Collision Errors: 0
Deferred: 0                                   Packet Too Short Errors: 0
SQE Test: 0                                   Packet Too Long Errors: 0
Timeout Errors: 30                            Packets Discarded by Adapter: 0
Single Collision Count: 0                     Receiver Start Count: 0
Multiple Collision Count: 0
Current HW Transmit Queue Length: 1

General Statistics:
-------------------
No mbuf Errors: 0
Adapter Reset Count: 30
Adapter Data Rate: 2000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous 64BitSupport 
	ChecksumOffload PrivateSegment LargeSend DataRateSet 

Qlogic combo Gigabit Ethernet PCI-Express Adapter (e4143a161410a003) Specific Statistics:
----------------------------------------------------------------------------------
Link Status: Up
Media Speed Selected: Autonegotiation
Media Speed Running: 1 Gbps Full Duplex
PCI Mode: PCI-Express X4
	Relaxed Ordering: Enabled
	MRR Size: 2048
Jumbo Frames: Disabled
Transmit TCP Segmentation Offload: Enabled
	TCP Segmentation Offload Packets Transmitted: 717479
Receive TCP Segment Aggregation: Disabled
Transmit and Receive Flow Control Status: Disabled
EOF
      @result = NetstatV.new(text, Hash.new).parse["ent2"]
    }
    it "parses the hardware MAC address" do
      expect(@result["Hardware Address"]).to eq("e4:1f:13:90:8f:f4")
    end
    it "parses the Receive Statistics" do
      expect(@result["Receive Statistics"]["Multicast Packets"]).to eq(124106624)
    end
    it "parses the Drive Flags" do
      expect(@result["Driver Flags"]).to eq(["Up",
                                             "Broadcast",
                                             "Running",
                                             "Simplex",
                                             "Promiscuous",
                                             "64BitSupport",
                                             "ChecksumOffload",
                                             "PrivateSegment",
                                             "LargeSend",
                                             "DataRateSet"])
    end
    it "parses the Transmit and Receive Flow Control Status" do
      expect(@result["Transmit and Receive Flow Control Status"]).to eq("Disabled")
    end
  end
end
