require "spec_helper"
require "entstat_musent"

describe Entstat_musent do 
  context "operating as stand alone" do
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
      @result = Netstat_v.new(text, Hash.new).parse["ent6"]
    }
    it "parses the hardware MAC address" do
      expect(@result["Hardware Address"]).to eq("6c:ae:8b:02:d7:68")
    end
    it "parses the two column statistics ouutput" do
      expect(@result["Receive Statistics"]["Interrupts"]).to eq(92721)
    end
  end

  context "operating as part of an 802.3ad link aggregation" do
    before(:all) {
      text = <<EOF
ETHERNET STATISTICS (ent4) :
Device Type: Gigabit Ethernet PCIe Adapter (e4145716e4142004)
Hardware Address: 40:f2:e9:5a:21:68

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 3                                    Packets: 0
Bytes: 372                                    Bytes: 0
Interrupts: 0                                 Interrupts: 0
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 0         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 0                          Broadcast Packets: 0
Multicast Packets: 3                          Multicast Packets: 0
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
	Simplex Promiscuous AlternateAddress 
	64BitSupport ChecksumOffload PrivateSegment 
	LargeSend DataRateSet 

Gigabit Ethernet PCIe Adapter (e4145716e4142004) Specific Statistics:
-----------------------------------------------------------------
Additional Driver Flags: Autonegotiate 
Entries to transmit timeout routine: 2
Link Status: Up
Media Speed Selected: Autonegotiation
Media Speed Running: 1000 Mbps Full Duplex
Transmit and Receive Flow Control Status: Enabled
	XON Flow Control Packets Transmitted: 0
	XON Flow Control Packets Received: 0
	XOFF Flow Control Packets Transmitted: 0
	XOFF Flow Control Packets Received: 0
Jumbo Frames: Disabled
TCP Segmentation Offload: Enabled
	TCP Segmentation Offload Packets Transmitted: 0
Assigned Interrupt Source Numbers: 
	Bus interrupt level 0 : 128520
	Bus interrupt level 1 : 128521
Receive statistics for RXQ number: 1
	Number of receive packets: 0
	Number of receive bytes: 0
	Number of receive interrupts: 0
	Number of receive bad packets: 0
	Number of receive packet drops: 0
	Number of RX mbufs allocated from system pool: 0
	Number of RX mbufs allocated from system pool for Jumbo: 0
	Number of system pool RX mbuf allocation failures: 0
	Number of rx_hog events: 0
	Receive TCP Segment Aggregation: Disabled
Transmit statistics for TXQ number: 1
	Number of transmit packets: 3
	Number of transmit bytes: 372
	Number of Unicast Packets: 3
	Number of Multicast packets: 0
	Number of Broadcast packets: 0
	Number of transmit packet drops: 0
	Number of transmit queue overflows: 0
	TCP segmentation offload packets transmitted: 0
	Maximum entries used on this transmit queue: 0

IEEE 802.3ad Port Statistics:
-----------------------------
	Actor System Priority: 0x8000
	Actor System: 40-F2-E9-5A-21-68
	Actor Operational Key: 0xBEEF
	Actor Port Priority: 0x0080
	Actor Port: 0x0001
	Actor State: 
		LACP activity: Active
		LACP timeout: Long
		Aggregation: Aggregatable
		Synchronization: IN_SYNC
		Collecting: Enabled
		Distributing: Disabled
		Defaulted: True
		Expired: True

	Partner System Priority: 0x0000
	Partner System: 00-00-00-00-00-00
	Partner Operational Key: 0x0000
	Partner Port Priority: 0x0000
	Partner Port: 0x0000
	Partner State: 
		LACP activity: Passive
		LACP timeout: Long
		Aggregation: Individual
		Synchronization: OUT_OF_SYNC
		Collecting: Disabled
		Distributing: Disabled
		Defaulted: False
		Expired: False

	Received LACPDUs: 0
	Transmitted LACPDUs: 3
	Received marker PDUs: 0
	Transmitted marker PDUs: 0
	Received marker response PDUs: 0
	Transmitted marker response PDUs: 0
	Received unknown PDUs: 0
	Received illegal PDUs: 0

-------------------------------------------------------------
Backup adapter - ent5:
======================

EOF
      @result = Netstat_v.new(text, Hash.new).parse["ent4"]
    }

    it "parses the hardware MAC address" do
      expect(@result["Hardware Address"]).to eq("40:f2:e9:5a:21:68")
    end

    it "parses the two column statistics ouutput" do
      expect(@result["Receive Statistics"]["Interrupts"]).to eq(0)
    end

    it "parses the Actor State LACP activity" do
      expect(@result["Actor State"]["LACP activity"]).to eq("Active")
    end
  end
end
