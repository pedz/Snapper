require "spec_helper"
require "entstat_goent"

describe EntstatGoent do 
  describe "#parse" do
    before(:context) {
      text = <<EOF
ETHERNET STATISTICS (ent2) :
Device Type: 4-Port 10/100/1000 Base-TX PCI-Express Adapter (14106803)
Hardware Address: e4:1f:13:fd:29:75

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 241295                               Packets: 238619
Bytes: 1995516069                             Bytes: 18097146
Interrupts: 0                                 Interrupts: 155955
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0

Max Packets on S/W Transmit Queue: 3         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 76                         Broadcast Packets: 1379
Multicast Packets: 88                         Multicast Packets: 5663
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
Adapter Data Rate: 2000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous 64BitSupport 
	ChecksumOffload LargeSend DataRateSet 

4-Port 10/100/1000 Base-TX PCI-Express Adapter (14106803) Specific Statistics:
------------------------------------------------------------------------------
Link Status: Up
Media Speed Selected: Auto negotiation
Media Speed Running: 1000 Mbps Full Duplex
PCI Mode: PCI-Express X4
    Relaxed Ordering: Enabled
    TLP Size: 256
    MRR Size: 4096
Jumbo Frames: Disabled
TCP Segmentation Offload: Enabled
	TCP Segmentation Offload Packets Transmitted: 121748
	TCP Segmentation Offload Packet Errors: 0
Transmit and Receive Flow Control Status: Disabled
Transmit and Receive Flow Control Threshold (High): 40960
Transmit and Receive Flow Control Threshold (Low): 20480
Transmit and Receive Storage Allocation (TX/RX): 4/44
EOF
      @result = NetstatV.new(text, Hash.new).parse["ent2"]
    }
    it "parses the hardware MAC address" do
      expect(@result["Hardware Address"]).to eq("e4:1f:13:fd:29:75")
    end
    it "parses the Receive Statistics" do
      expect(@result["Receive Statistics"]["Multicast Packets"]).to eq(5663)
    end
    it "parses the Drive Flags" do
      expect(@result["Driver Flags"]).to eq(["Up",
                                             "Broadcast",
                                             "Running",
                                             "Simplex",
                                             "Promiscuous",
                                             "64BitSupport",
                                             "ChecksumOffload",
                                             "LargeSend",
                                             "DataRateSet"])
    end
    it "parses the Transmit and Receive Flow Control Status" do
      expect(@result["Transmit and Receive Flow Control Status"]).to eq("Disabled")
    end
  end
end
