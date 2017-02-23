require "spec_helper"
require "entstat_lnc2ent"

describe EntstatLnc2ent do 
  describe "#parse" do
    before(:context) {
      text = <<EOF
ETHERNET STATISTICS (ent104) :
Device Type: PCIe3 4-Port 10GbE SR Adapter 
Hardware Address: 98:be:94:67:f5:14

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 46468479                             Packets: 2187992141
Bytes: 124976348939                           Bytes: 3193262576144
Interrupts: 726065                            Interrupts: 271155215
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 38        
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 16

Broadcast Packets: 0                          Broadcast Packets: 8767513
Multicast Packets: 2893                       Multicast Packets: 544830
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
Current HW Transmit Queue Length: 16

General Statistics:
-------------------
No mbuf Errors: 0
Adapter Reset Count: 5
Adapter Data Rate: 20000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous AlternateAddress 
	64BitSupport ChecksumOffload LargeSend 
	DataRateSet 

PCIe3 4-Port 10GbE SR Adapter 
-------------------------------------------------------------

Device Statistics:
------------------
Device ID: df1020e21410e304
Version: 1
Physical Port Link Status: Up
Logical Port Link Status: Up
Physical Port Speed: 10Gbps Full Duplex
PCI Mode: PCI-Express X8
	PCIe Link Speed: 8.0 GT/s
	TLP Size: 512
	MRR Size: 4096
	Relaxed Ordering: Enabled
Assigned Interrupt Source Numbers: 6
	6228	MGT
	6229	NIC TX
	6230	NIC TX
	6231	NIC RX
	6232	NIC RX
	6233	NIC RX
Unassigned Interrupt Source Numbers: 10
External Loopback Changeable: No
External Loopback: Disabled
Internal Loopback: Disabled
Physical Port Promiscuous Mode Changeable: Yes
Physical Port Promiscuous Mode: Enabled
Logical Port Promiscuous Mode: Enabled
Physical Port All Multicast Mode Changeable: Yes
Physical Port All Multicast Mode: Disabled
Logical Port All Multicast Mode: Disabled
Multicast Addresses Enabled: 3
Maximum Exact Match Multicast Filters: 32
Maximum Inexact Match Multicast Filters: 0
Physical Port MTU Changeable: Yes
Physical Port MTU: 9014
Logical Port MTU: 9014
Jumbo Frames: Enabled
Enabled VLAN IDs:
	0148  
Transmit and receive flow control status: Enabled
	Number of XOFF packets transmitted: 0
	Number of XON packets transmitted: 0
	Number of XOFF packets received: 0
	Number of XON packets received: 0
Receive TCP Segment Aggregation: Enabled
	Receive TCP Segment Aggregation Large Packets Created: 267403138
	Receive TCP Packets Aggregated into Large Packets: 2129584520
	Receive TCP Payload Bytes Aggregated into Large Packets: 3081137589264
	Receive TCP Segment Aggregation Average Packets Aggregated: 7
	Receive TCP Segment Aggregation Maximum Packets Aggregated: 16
Transmit TCP Segmentation Offload: Enabled
	Transmit TCP Segmentation Offload Packets Transmitted: 4345955
	Transmit TCP Segmentation Offload Maximum Packet Size: 65218
Transmit Q0 Statistics:
	Transmit Q Packets: 25076591
	Transmit Q Multicast Packets: 2870
	Transmit Q Broadcast Packets: 0
	Transmit Q Flip and Run Packets: 2670
	Transmit Q Bytes: 24276323491
	Transmit Q No Buffers: 0
	Transmit Q Dropped Packets: 0
	Transmit SWQ Cur Packets: 0
	Transmit SWQ Max Packets: 29
	Transmit SWQ Dropped Packets: 0
	Transmit OFQ Cur Packets: 0
	Transmit OFQ Max Packets: 0
Transmit Q1 Statistics:
	Transmit Q Packets: 21392257
	Transmit Q Multicast Packets: 23
	Transmit Q Broadcast Packets: 0
	Transmit Q Flip and Run Packets: 0
	Transmit Q Bytes: 100700152967
	Transmit Q No Buffers: 0
	Transmit Q Dropped Packets: 0
	Transmit SWQ Cur Packets: 0
	Transmit SWQ Max Packets: 9
	Transmit SWQ Dropped Packets: 0
	Transmit OFQ Cur Packets: 0
	Transmit OFQ Max Packets: 0
Receive Q0 Statistics:
	Receive Q Packets: 9382364
	Receive Q Multicast Packets: 543590
	Receive Q Broadcast Packets: 8767615
	Receive Q Bytes: 952469607
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q1 Statistics:
	Receive Q Packets: 563205966
	Receive Q Multicast Packets: 1089
	Receive Q Broadcast Packets: 0
	Receive Q Bytes: 814791630131
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q2 Statistics:
	Receive Q Packets: 1615438976
	Receive Q Multicast Packets: 162
	Receive Q Broadcast Packets: 0
	Receive Q Bytes: 2377570031173
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0

Additional Statistics:
----------------------
SLI PORT Event Counters: 
	Error Events: 0
	Over-Temp Events: 0
	Norm-Temp Events: 0
	NVLOG Events: 0
	Out of RQE Events: 0
	Solicited Events: 0
Adapter Physical Port Counters: 
	Total Number of Packets Sent: 104282077
	Number of Unicast Packets Sent: 104279291
	Number of Multicast Packets Sent: 2786
	Number of Broadcast Packets Sent: 0
	Total Bytes Sent: 128879195462
	Number of Unicast Bytes Sent: 29822580
	Number of Multicast Bytes Sent: 354002
	Number of Broadcast Bytes Sent: 0
	Number of TX Packets without Errors Discarded: 0
	Number of TX Packets with Errors Dropped: 0
	Number of Pause Frames Sent: 0
	Number of Pause ON Frames Sent: 0
	Number of Pause OFF Frames Sent: 0
	Number of Frames Failed due to Internal MAC TX Error: 0
	Number of MAC Control Frames Sent: 0
	Number of 64-Byte Packets Sent: 13535722
	Number of 65-127 Byte Packets Sent: 5818668
	Number of 128-255 Byte Packets Sent: 7908990
	Number of 256-511 Byte Packets Sent: 2553010
	Number of 512-1023 Byte Packets Sent: 2329784
	Number of 1024-1518 Byte Packets Sent: 60342991
	Number of 1519-2047 Byte Packets Sent: 9504897
	Number of 2048-4095 Byte Packets Sent: 95499
	Number of 4096-8191 Byte Packets Sent: 500883
	Number of 8192-9216 Byte Packets Sent: 1691633
	Number of LSO Packets Sent: 4330034
	Total Number of Packets Received: 2187170345
	Number of Unicast Packets Received: 2177918458
	Number of Multicast Packets Received: 540593
	Number of Broadcast Packets Received: 8711294
	Total Bytes Received: 3201706174710
	Number of Unicast Bytes Received: 3200727901096
	Number of Multicast Bytes Received: 66140084
	Number of Broadcast Bytes Received: 912133530
	Number of Packets Received and Dropped due to Unknown Protocol: 0
	Number of Received Packets without Errors Discarded: 0
	Number of Received Packets with Errors Dropped: 0
	Number of Packets Received with CRC/FCS Error: 0
	Number of Frames Received with Alignment Error: 0
	Number of Packets Received with Symbol Error: 0
	Number of Pause Frames Received: 0
	Number of Pause ON Frames Received: 0
	Number of Pause OFF Frames Received: 0
	Number of Frames Received that Exceed the Maximum Permitted Frame Size: 0
	Number of Frames Failed due to Internal MAC RX Error: 0
	Number of Packets Received That Were Less Than 64 Octets: 0
	Number of Packets Received That Were Longer Than 1518 Octets: 1797179254
	Number of JABBER Packets Received: 0
	Number of Fragment Packets Received: 0
	Number of MAC Control Frames Received: 0
	Number of MAC Control Frames Received with Unknown Opcode: 0
	Number of Packets Received with Out of Range Errors: 0
	Number of Packets Received with In Range Errors : 0
	Number of Receive VLAN Mismatch Errors: 0
	Number of Receive Address Match Errors: 2177741216
	Number of Received Packets Too Short and Dropped (IP Length < IP Header Len): 0
	Number of Received Packets Too Small and Dropped (IP Length > Pkt Len): 0
	Number of Received Packets Dropped due to Invalid TCP Length: 0
	Number of Received Packets with Too Small Headers and Dropped: 0
	Number of Received Packets with IP Checksum Errors: 0
	Number of Received RUNT Packets Dropped: 0
	Number of Received Packets with UDP Checksum Errors: 0
	Number of Received Packets with TCP Checksum Errors: 0
	Number of Non-RSS Packets Received: 9319901
	Number of IPv4 Packets Received: 2181463129
	Number of IPv6 Packets Received: 162273
	Number of IPv4 Bytes Received: 3201300522218
	Number of IPv6 Bytes Received: 26129536
	Number of NIC-Only Packets Received: 2187170343
	Number of TCP Packets Received: 0
	Number of iSCSI Packets Received: 0
	Number of Management Packets Received: 0
	Number of Unicast Packets Received and Switched: 0
	Number of Multicast Packets Received and Switched: 0
	Number of Broadcast Packets Received and Switched: 0
	Number of Forwarded Packets: 0
	Number of Times Receive FIFO Overflow Occurred: 0
	Number of Received Packets Dropped due to Too Many Fragments: 0
	Number of Received Packets Dropped due to Invalid Queue: 0
	Number of Received Packets Dropped due to MTU limit Exceeded: 0
	Number of 64 Byte Packets Received: 126185
	Number of 65-127 Byte Packets Received: 38146678
	Number of 128-255 Byte Packets Received: 5885171
	Number of 256-511 Byte Packets Received: 3563249
	Number of 512-1023 Byte Packets Received: 67614680
	Number of 1024-1518 Byte Packets Received: 274655128
	Number of 1519-2047 Byte Packets Received: 1797165209
	Number of 2048-4095 Byte Packets Received: 196
	Number of 4096-8191 Byte Packets Received: 311
	Number of 8192-9216 Byte Packets Received: 13538
DCBX Status: Enabled
	TLV Exchange Complete
	TC State   [0x00000009] Enabled
	PFC State  [0x80000000] Error
	QCN State  [0x00000000] Disabled
	APPL State [0x00000009] Enabled
	Priority Flow Control: Disabled
	Traffic Class	Bandwidth	Priority
	-------------	---------	--------
	   0		   100%		0 1 2 3 4 5 6 7 
	   1		   0%		
	   2		   0%		
	   3		   0%		
	   4		   0%		
	   5		   0%		
	   6		   0%		
	   7		   0%		
	Application	Priority
	-----------	--------
	   0x8906	3 
Controller Version: 00000B00

IEEE 802.3ad Port Statistics:
-----------------------------
	Actor System Priority: 0x8000
	Actor System: 98-BE-94-67-F5-14
	Actor Operational Key: 0xBEEF
	Actor Port Priority: 0x0080
	Actor Port: 0x0069
	Actor State: 
		LACP activity: Active
		LACP timeout: Long
		Aggregation: Aggregatable
		Synchronization: IN_SYNC
		Collecting: Enabled
		Distributing: Enabled
		Defaulted: False
		Expired: False

	Partner System Priority: 0x7F9B
	Partner System: 00-23-04-EE-BE-9E
	Partner Operational Key: 0x0029
	Partner Port Priority: 0x8000
	Partner Port: 0x232D
	Partner State: 
		LACP activity: Active
		LACP timeout: Long
		Aggregation: Aggregatable
		Synchronization: IN_SYNC
		Collecting: Enabled
		Distributing: Enabled
		Defaulted: False
		Expired: False

	Received LACPDUs: 2622
	Transmitted LACPDUs: 2689
	Received marker PDUs: 0
	Transmitted marker PDUs: 0
	Received marker response PDUs: 0
	Transmitted marker response PDUs: 0
	Received unknown PDUs: 0
	Received illegal PDUs: 0

-------------------------------------------------------------

EOF
      @result = NetstatV.new(text, Hash.new).parse["ent104"]
    }

    it "parses Adapter Reset Count" do
      expect(@result["Adapter Reset Count"]).to eq(5)
    end
    
    it "parses Enabled VLAN IDs" do
      expect(@result["Enabled VLAN IDs"][0]).to eq(148)
    end
    
    it "pops the stack at the end of the VLAN IDs correctly" do
      expect(@result["Transmit and receive flow control status"]).to eq("Enabled")
    end
    
    it "correctly nests statistics" do
      expect(@result["Transmit Q1 Statistics"]["Transmit Q Packets"]).to eq(21392257)
    end
  end
end
