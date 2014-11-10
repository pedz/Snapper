require "spec_helper"
require "netstat_v_musent"

describe Netstat_v_musent do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent6) :
Device Type: Gigabit Ethernet PCIe Adapter (e4145716e4142004)
Hardware Address: 6c:ae:8b:02:d7:68

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 0                                    Packets: 140451
Bytes: 0                                      Bytes: 93120838
Interrupts: 0                                 Interrupts: 92721
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 2046
                                              Bad Packets: 0

Max Packets on S/W Transmit Queue: 0         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 0                          Broadcast Packets: 62307
Multicast Packets: 0                          Multicast Packets: 12018
No Carrier Sense: 0                           CRC Errors: 0
DMA Underrun: 0                               DMA Overrun: 0
Lost CTS Errors: 0                            Alignment Errors: 0
Max Collision Errors: 0                       No Resource Errors: 0
Late Collision Errors: 0                      Receive Collision Errors: 0
Deferred: 0                                   Packet Too Short Errors: 0
SQE Test: 0                                   Packet Too Long Errors: 0
Timeout Errors: 0                             Packets Discarded by Adapter: 0
Single Collision Count: 0                     Receiver Start Count: 0
Multiple Collision Count: 0
Current HW Transmit Queue Length: 0

General Statistics:
-------------------
No mbuf Errors: 0
Adapter Reset Count: 0
Adapter Data Rate: 2000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous 64BitSupport 
	ChecksumOffload PrivateSegment LargeSend DataRateSet 

Gigabit Ethernet PCIe Adapter (e4145716e4142004) Specific Statistics:
-----------------------------------------------------------------
Additional Driver Flags: Autonegotiate 
Entries to transmit timeout routine: 0
Link Status: Up
Media Speed Selected: Autonegotiation
Media Speed Running: 1000 Mbps Full Duplex
Transmit and Receive Flow Control Status: Enabled
	XON Flow Control Packets Transmitted: 0
	XON Flow Control Packets Received: 0
	XOFF Flow Control Packets Transmitted: 0
	XOFF Flow Control Packets Received: 0
Jumbo Frames: Enabled
TCP Segmentation Offload: Enabled
	TCP Segmentation Offload Packets Transmitted: 0
Receive TCP Segment Aggregation: Disabled

--------------------------------------------------------------
Virtual Adapter: ent0

EOF
    @result = Netstat_v.new(text).result["ent6"]
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("6c:ae:8b:02:d7:68")
  end
  it "parses the two column statistics ouutput" do
    expect(@result["Receive Statistics"]["Interrupts"]).to eq(92721)
  end
end
