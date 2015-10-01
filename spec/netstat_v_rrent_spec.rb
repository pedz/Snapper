require "spec_helper"
require "netstat_v_rrent"

describe Netstat_v_rrent do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent10) :
Device Type: 10 Gigabit Ethernet Adapter (ct3)
Hardware Address: 34:40:b5:b6:bb:18

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 22227                                Packets: 162898
Bytes: 3232073                                Bytes: 98167179
Interrupts: 0                                 Interrupts: 114101
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0

Max Packets on S/W Transmit Queue: 1         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 67                         Broadcast Packets: 61206
Multicast Packets: 50                         Multicast Packets: 13400
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
Adapter Reset Count: 1
Adapter Data Rate: 20000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous 64BitSupport 
	ChecksumOffload LargeSend DataRateSet 

10 Gigabit Ethernet Adapter (ct3) Specific Statistics:
------------------------------------------------------
Parent HBA Device: hba0
Link Status: Up
Media Speed Running: 10 Gbps Full Duplex
QSets Running: True
Number of QSets Allocated: 2
Number of Promiscuous Mode Users: 1
Number of Multicast Mode Users:   0
Number of Multicast Addresses:    2
Library Memory Usage: 193 MB
Driver Memory Usage: 1 MB
Jumbo Frames: Enabled
Adapter Reset Count Due To TX Timout: 0
Adapter Reset Count Due To Disable Enable: 1
Transmit TCP Segmentation Offload: Enabled
	TCP Segmentation Offload Packets Transmitted: 14
	TCP Segmentation Offload Maximum Packet Size: 1947
Receive TCP Segment Aggregation: Disabled
Lifetime Number of Transmit Packets Overflowed: 0
Lifetime Number of Transmit Bytes Overflowed:   0
QSet[0] Current Number of Transmit Packets Overflowed: 0
QSet[0] Current Number of Transmit Bytes Overflowed:   0
QSet[1] Current Number of Transmit Packets Overflowed: 0
QSet[1] Current Number of Transmit Bytes Overflowed:   0

--------------------------------------------------------------
Virtual Adapter: ent14

EOF
    @result = Netstat_v.new(text).result["ent10"].to_hash
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("34:40:b5:b6:bb:18")
  end
end
