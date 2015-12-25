require "spec_helper"
require "entstat_shient"

describe EntstatShient do 
  before(:context) {
    text = <<EOF
ETHERNET STATISTICS (ent1) :
Device Type: PCIe2 4-Port Adapter (10GbE SFP+) (e4148a1614109304)
Hardware Address: 40:f2:e9:d3:45:a1
Elapsed Time: 0 days 0 hours 0 minutes 0 seconds

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 0                                    Packets: 0
Bytes: 0                                      Bytes: 0
Interrupts: 0                                 Interrupts: 0
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 0         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 0                          Broadcast Packets: 0
Multicast Packets: 0                          Multicast Packets: 0
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
Adapter Reset Count: 3
Adapter Data Rate: 20000
Driver Flags: Up Broadcast Simplex 
	Limbo 64BitSupport ChecksumOffload 
	LargeSend DataRateSet 

PCIe2 4-Port Adapter (10GbE SFP+) (e4148a1614109304)
-------------------------------------------------------------

Device Statistics:
------------------
Device ID: e4148a1614109304
Version: 1
Physical Port Link Status: Down
Logical Port Link Status: Down
Physical Port Speed: Auto-negotiation
PCI Mode: PCI-Express X8
	PCIe Link Speed: 5.0 GT/s
	TLP Size: 512
	MRR Size: 4096
	Relaxed Ordering: Enabled
Assigned Interrupt Source Numbers: 
	15344	MGT
	15345	NIC TX,RX
	15346	NIC RX
	15347	NIC RX
	15348	NIC RX
	15349	Unused
	15350	Unused
	15351	Unused
External Loopback Changeable: No
External Loopback: Disabled
Internal Loopback: Disabled
Physical Port Promiscuous Mode Changeable: Yes
Physical Port Promiscuous Mode: Disabled
Logical Port Promiscuous Mode: Disabled
Physical Port All Multicast Mode Changeable: Yes
Physical Port All Multicast Mode: Disabled
Logical Port All Multicast Mode: Disabled
Multicast Addresses Enabled: 0
Maximum Exact Match Multicast Filters: 0
Maximum Inxact Match Multicast Filters: 256
Physical Port MTU Changeable: Yes
Physical Port MTU: 9014
Logical Port MTU: 9014
Jumbo Frames: Enabled
Transmit and receive flow control status: Enabled
	Number of XOFF packets transmitted: 0
	Number of XON packets transmitted: 0
	Number of XOFF packets received: 0
	Number of XON packets received: 0
Receive TCP Segment Aggregation: Enabled
	Receive TCP Segment Aggregation Large Packets Created: 0
	Receive TCP Packets Aggregated into Large Packets: 0
	Receive TCP Payload Bytes Aggregated into Large Packets: 0
	Receive TCP Segment Aggregation Average Packets Aggregated: 0
	Receive TCP Segment Aggregation Maximum Packets Aggregated: 0
Transmit TCP Segmentation Offload: Enabled
	Transmit TCP Segmentation Offload Packets Transmitted: 0
	Transmit TCP Segmentation Offload Maximum Packet Size: 0
Transmit Q0 Statistics:
	Transmit Q Packets: 0
	Transmit Q Multicast Packets: 0
	Transmit Q Broadcast Packets: 0
	Transmit Q Bytes: 0
	Transmit Q No Buffers: 0
	Transmit Q Dropped Packets: 0
	Transmit SWQ Cur Packets: 0
	Transmit SWQ Max Packets: 0
	Transmit SWQ Dropped Packets: 0
	Transmit OFQ Cur Packets: 0
	Transmit OFQ Max Packets: 0
Receive Q0 Statistics:
	Receive Q Packets: 0
	Receive Q Multicast Packets: 0
	Receive Q Broadcast Packets: 0
	Receive Q Bytes: 0
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q1 Statistics:
	Receive Q Packets: 0
	Receive Q Multicast Packets: 0
	Receive Q Broadcast Packets: 0
	Receive Q Bytes: 0
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q2 Statistics:
	Receive Q Packets: 0
	Receive Q Multicast Packets: 0
	Receive Q Broadcast Packets: 0
	Receive Q Bytes: 0
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0
Receive Q3 Statistics:
	Receive Q Packets: 0
	Receive Q Multicast Packets: 0
	Receive Q Broadcast Packets: 0
	Receive Q Bytes: 0
	Receive Q No Buffers: 0
	Receive Q Errors: 0
	Receive Q Dropped Packets: 0

Additional Statistics:
----------------------
rx_bytes:	0
rx_error_bytes:	0
rx_ucast_packets:	0
rx_mcast_packets:	0
rx_bcast_packets:	0
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
tx_bytes:	0
tx_error_bytes:	0
tx_ucast_packets:	0
tx_mcast_packets:	0
tx_bcast_packets:	0
tx_mac_errors:	0
tx_carrier_errors:	0
tx_single_collisions:	0
tx_multi_collisions:	0
tx_deferred:	0
tx_excess_collisions:	0
tx_late_collisions:	0
tx_total_collisions:	0
tx_64_byte_packets:	0
tx_65_to_127_byte_packets:	0
tx_128_to_255_byte_packets:	0
tx_256_to_511_byte_packets:	0
tx_512_to_1023_byte_packets:	0
tx_1024_to_1522_byte_packets:	0
tx_1523_to_9022_byte_packets:	0
tx_pause_frames:	0
recoverable_errors:	0
unrecoverable_errors:	0
Tx LPI entry count:	0
	[q-0]: rx_bytes:	0
	[q-0]: rx_ucast_packets:	0
	[q-0]: rx_mcast_packets:	0
	[q-0]: rx_bcast_packets:	0
	[q-0]: rx_discards:	0
	[q-0]: rx_phy_ip_err_discards:	0
	[q-0]: rx_csum_offload_errors:	0
	[q-0]: tx_bytes:	0
	[q-0]: tx_ucast_packets:	0
	[q-0]: tx_mcast_packets:	0
	[q-0]: tx_bcast_packets:	0
	[q-1]: rx_bytes:	0
	[q-1]: rx_ucast_packets:	0
	[q-1]: rx_mcast_packets:	0
	[q-1]: rx_bcast_packets:	0
	[q-1]: rx_discards:	0
	[q-1]: rx_phy_ip_err_discards:	0
	[q-1]: rx_csum_offload_errors:	0
	[q-1]: tx_bytes:	0
	[q-1]: tx_ucast_packets:	0
	[q-1]: tx_mcast_packets:	0
	[q-1]: tx_bcast_packets:	0
	[q-2]: rx_bytes:	0
	[q-2]: rx_ucast_packets:	0
	[q-2]: rx_mcast_packets:	0
	[q-2]: rx_bcast_packets:	0
	[q-2]: rx_discards:	0
	[q-2]: rx_phy_ip_err_discards:	0
	[q-2]: rx_csum_offload_errors:	0
	[q-2]: tx_bytes:	0
	[q-2]: tx_ucast_packets:	0
	[q-2]: tx_mcast_packets:	0
	[q-2]: tx_bcast_packets:	0
	[q-3]: rx_bytes:	0
	[q-3]: rx_ucast_packets:	0
	[q-3]: rx_mcast_packets:	0
	[q-3]: rx_bcast_packets:	0
	[q-3]: rx_discards:	0
	[q-3]: rx_phy_ip_err_discards:	0
	[q-3]: rx_csum_offload_errors:	0
	[q-3]: tx_bytes:	0
	[q-3]: tx_ucast_packets:	0
	[q-3]: tx_mcast_packets:	0
	[q-3]: tx_bcast_packets:	0
-------------------------------------------------------------
EOF
    @result = NetstatV.new(text, Hash.new).parse["ent1"]
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("40:f2:e9:d3:45:a1")
  end

  it "parses the [q-0] stuff" do
    expect(@result["q"][0]["tx_bytes"]).to eq(0)
  end
end
