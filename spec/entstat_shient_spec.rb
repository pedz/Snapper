require "spec_helper"
require "entstat_shient"

describe EntstatShient do 
  describe "#parse" do
    before(:context) {
      text = <<EOF
ETHERNET STATISTICS (ent101) :
Device Type: PCIe2 4-Port Adapter (10GbE SFP+) (e4148a1614109304)

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 96671                                Packets: 113841408
Bytes: 20075544                               Bytes: 7992223397
Interrupts: 83414                             Interrupts: 55576285
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 1         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 62                         Broadcast Packets: 200086
Multicast Packets: 733                        Multicast Packets: 7388
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

PCIe2 4-Port Adapter (10GbE SFP+) (e4148a1614109304)
-------------------------------------------------------------

Device Statistics:
------------------
Device ID: e4148a1614109304
Version: 1
Physical Port Link Status: Up
Logical Port Link Status: Up
Physical Port Speed: 10Gbps Full Duplex
PCI Mode: PCI-Express X8
	PCIe Link Speed: 5.0 GT/s
	TLP Size: 512
	MRR Size: 4096
	Relaxed Ordering: Enabled
Assigned Interrupt Source Numbers: 
	32800	MGT
	32801	NIC TX,RX
	32802	NIC RX
	32803	NIC RX
	32804	NIC RX
	32805	Unused
	32806	Unused
	32807	Unused
	32808	Unused
	32809	Unused
	32810	Unused
	32811	Unused
	32812	Unused
	32813	Unused
	32814	Unused
	32815	Unused
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
Maximum Exact Match Multicast Filters: 0
Maximum Inexact Match Multicast Filters: 256
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
	Receive TCP Segment Aggregation Large Packets Created: 38505601
	Receive TCP Packets Aggregated into Large Packets: 96063485
	Receive TCP Payload Bytes Aggregated into Large Packets: 10534493
	Receive TCP Segment Aggregation Average Packets Aggregated: 2
	Receive TCP Segment Aggregation Maximum Packets Aggregated: 16
Transmit TCP Segmentation Offload: Enabled
	Transmit TCP Segmentation Offload Packets Transmitted: 811
	Transmit TCP Segmentation Offload Maximum Packet Size: 27354
Transmit Q0 Statistics:
	Transmit Q Packets: 96671
	Transmit Q Multicast Packets: 733
	Transmit Q Broadcast Packets: 62
	Transmit Q Bytes: 20075544
	Transmit Q No Buffers: 0
	Transmit Q Dropped Packets: 0
	Transmit SWQ Cur Packets: 0
	Transmit SWQ Max Packets: 1
	Transmit SWQ Dropped Packets: 0
	Transmit OFQ Cur Packets: 0
	Transmit OFQ Max Packets: 0
Receive Q0 Statistics:
	Receive Q Packets: 118634
	Receive Q Multicast Packets: 4169
	Receive Q Broadcast Packets: 16921
	Receive Q Bytes: 12501818
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q1 Statistics:
	Receive Q Packets: 22640221
	Receive Q Multicast Packets: 236
	Receive Q Broadcast Packets: 119149
	Receive Q Bytes: 1591601211
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q2 Statistics:
	Receive Q Packets: 54315706
	Receive Q Multicast Packets: 2205
	Receive Q Broadcast Packets: 43510
	Receive Q Bytes: 3810245145
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q3 Statistics:
	Receive Q Packets: 36766847
	Receive Q Multicast Packets: 778
	Receive Q Broadcast Packets: 20506
	Receive Q Bytes: 2577875223
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0

Additional Statistics:
----------------------
rx_bytes:	8447586024
rx_error_bytes:	0
rx_ucast_packets:	113633934
rx_mcast_packets:	7388
rx_bcast_packets:	200064
rx_crc_errors:	0
rx_align_errors:	0
rx_undersize_packets:	0
rx_oversize_packets:	0
rx_fragments:	0
rx_jabbers:	0
rx_discards:	0
rx_filtered_packets:	0
rx_mf_tag_discard:	0
pfc_frames_received:	0
pfc_frames_sent:	0
rx_brb_discard:	0
rx_brb_truncate:	0
rx_pause_frames:	0
rx_mac_ctrl_frames:	0
rx_constant_pause_events:	0
rx_phy_ip_err_discards:	0
rx_csum_offload_errors:	0
tx_bytes:	20669946
tx_error_bytes:	0
tx_ucast_packets:	98683
tx_mcast_packets:	733
tx_bcast_packets:	62
tx_mac_errors:	0
tx_carrier_errors:	0
tx_single_collisions:	0
tx_multi_collisions:	0
tx_deferred:	0
tx_excess_collisions:	0
tx_late_collisions:	0
tx_total_collisions:	0
tx_64_byte_packets:	194
tx_65_to_127_byte_packets:	62962
tx_128_to_255_byte_packets:	21680
tx_256_to_511_byte_packets:	5717
tx_512_to_1023_byte_packets:	4479
tx_1024_to_1522_byte_packets:	4436
tx_1523_to_9022_byte_packets:	1
tx_pause_frames:	0
recoverable_errors:	0
unrecoverable_errors:	0
Tx LPI entry count:	0
	[q-0]: rx_bytes:	12976354
	[q-0]: rx_ucast_packets:	97544
	[q-0]: rx_mcast_packets:	4169
	[q-0]: rx_bcast_packets:	16921
	[q-0]: rx_discards:	0
	[q-0]: rx_phy_ip_err_discards:	0
	[q-0]: rx_csum_offload_errors:	0
	[q-0]: tx_bytes:	20669946
	[q-0]: tx_ucast_packets:	98683
	[q-0]: tx_mcast_packets:	733
	[q-0]: tx_bcast_packets:	62
	[q-1]: rx_bytes:	1682159976
	[q-1]: rx_ucast_packets:	22520836
	[q-1]: rx_mcast_packets:	236
	[q-1]: rx_bcast_packets:	119133
	[q-1]: rx_discards:	0
	[q-1]: rx_phy_ip_err_discards:	0
	[q-1]: rx_csum_offload_errors:	0
	[q-1]: tx_bytes:	0
	[q-1]: tx_ucast_packets:	0
	[q-1]: tx_mcast_packets:	0
	[q-1]: tx_bcast_packets:	0
	[q-2]: rx_bytes:	4027507083
	[q-2]: rx_ucast_packets:	54269991
	[q-2]: rx_mcast_packets:	2205
	[q-2]: rx_bcast_packets:	43504
	[q-2]: rx_discards:	0
	[q-2]: rx_phy_ip_err_discards:	0
	[q-2]: rx_csum_offload_errors:	0
	[q-2]: tx_bytes:	0
	[q-2]: tx_ucast_packets:	0
	[q-2]: tx_mcast_packets:	0
	[q-2]: tx_bcast_packets:	0
	[q-3]: rx_bytes:	2724942611
	[q-3]: rx_ucast_packets:	36745563
	[q-3]: rx_mcast_packets:	778
	[q-3]: rx_bcast_packets:	20506
	[q-3]: rx_discards:	0
	[q-3]: rx_phy_ip_err_discards:	0
	[q-3]: rx_csum_offload_errors:	0
	[q-3]: tx_bytes:	0
	[q-3]: tx_ucast_packets:	0
	[q-3]: tx_mcast_packets:	0
	[q-3]: tx_bcast_packets:	0

IEEE 802.3ad Port Statistics:
-----------------------------
	Actor System Priority: 0x8000
	Actor System: 98-BE-94-63-A5-7C
	Actor Operational Key: 0xBEEF
	Actor Port Priority: 0x0080
	Actor Port: 0x0066
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
	Partner System: 00-23-04-EE-BE-A2
	Partner Operational Key: 0x0023
	Partner Port Priority: 0x8000
	Partner Port: 0x2419
	Partner State: 
		LACP activity: Active
		LACP timeout: Long
		Aggregation: Aggregatable
		Synchronization: IN_SYNC
		Collecting: Enabled
		Distributing: Enabled
		Defaulted: False
		Expired: False

	Received LACPDUs: 676
	Transmitted LACPDUs: 686
	Received marker PDUs: 0
	Transmitted marker PDUs: 0
	Received marker response PDUs: 0
	Transmitted marker response PDUs: 0
	Received unknown PDUs: 0
	Received illegal PDUs: 0

-------------------------------------------------------------
EOF
      @result = NetstatV.new(text, Hash.new).parse["ent101"]
    }

    it "parses Adapter Reset Count" do
      expect(@result["Adapter Reset Count"]).to eq(1)
    end
    
    it "parses Enabled VLAN IDs" do
      expect(@result["Enabled VLAN IDs"][0]).to eq(148)
    end
    
    it "pops the stack at the end of the VLAN IDs correctly" do
      expect(@result["Transmit and receive flow control status"]).to eq("Enabled")
    end
    
    it "pops the stack at the end of the per queue statistics" do
      expect(@result["rx_bytes"]).to eq(8447586024)
    end
    
    it "parses the [q-0] stuff" do
      expect(@result["q"][0]["tx_bytes"]).to eq(20669946)
    end
  end
end
