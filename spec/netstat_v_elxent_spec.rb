require "spec_helper"
require "netstat_v_elxent"

describe Netstat_v_elxent do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent0) :
Device Type: PCIe2 2-port 10GbE SR Adapter
Hardware Address: 00:00:c9:d9:d8:96

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 382830643                            Packets: 463507064
Bytes: 366357143927                           Bytes: 480756412571
Interrupts: 0                                 Interrupts: 157147159
Transmit Errors: 0                            Receive Errors: 156783
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 354       
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 8

Broadcast Packets: 0                          Broadcast Packets: 83839
Multicast Packets: 0                          Multicast Packets: 72738
No Carrier Sense: 0                           CRC Errors: 0
DMA Underrun: 0                               DMA Overrun: 156783
Lost CTS Errors: 0                            Alignment Errors: 0
Max Collision Errors: 0                       No Resource Errors: 0
Late Collision Errors: 0                      Receive Collision Errors: 0
Deferred: 0                                   Packet Too Short Errors: 0
SQE Test: 0                                   Packet Too Long Errors: 0
Timeout Errors: 0                             Packets Discarded by Adapter: 0
Single Collision Count: 0                     Receiver Start Count: 0
Multiple Collision Count: 0
Current HW Transmit Queue Length: 8

General Statistics:
-------------------
No mbuf Errors: 0
Adapter Reset Count: 0
Adapter Data Rate: 20000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous 64BitSupport 
	ChecksumOffload LargeSend DataRateSet 

PCIe2 2-port 10GbE SR Adapter (a21910071410d003) Specific Statistics:
---------------------------------------------------------------------
Link Status: Up
Media Speed Running: 10 Gbps Full Duplex
PCI Mode: PCI-Express X8
	Relaxed Ordering: Disabled
	TLP Size: 512
	MRR Size: 4096
	PCIe Link Speed: 5.0 Gbps 
Firmware Operating Mode: Legacy
Jumbo Frames: Disabled
Transmit TCP segmentation offload: Enabled
Receive TCP segment aggregation: Enabled
Transmit and receive flow control status: Enabled
	Number of XOFF packets transmitted: 0
	Number of XON packets transmitted: 0
	Number of XOFF packets received: 0
	Number of XON packets received: 8
Receive statistics for RXQ number: 0
	Number of receive interrupts: 78848
	Number of receive packets: 81107
	Number of receive bytes: 35175670
	Number of receive packet drops: 0
	Number of RX mbufs allocated from system pool: 0
	Number of system pool RX mbuf allocation failures: 0
	Number of empty EQ events: 0
	Number of no fragment errors: 0
	Number of rx_limit events: 0
Receive statistics for RXQ number: 1
	Number of receive interrupts: 78995959
	Number of receive packets: 210174400
	Number of receive bytes: 212114251244
	Number of receive packet drops: 0
	Number of RX mbufs allocated from system pool: 0
	Number of system pool RX mbuf allocation failures: 0
	Number of empty EQ events: 0
	Number of no fragment errors: 0
	Number of rx_limit events: 75
	TCP segment aggregation large packets created: 10904997
	TCP packets aggregated into large packets: 61090221
	TCP payload bytes aggregated into large packets: 75586812243
	TCP segment aggregation average packets aggregated: 5
	TCP segment aggregation maximum packets aggregated: 154
Receive statistics for RXQ number: 2
	Number of receive interrupts: 78072562
	Number of receive packets: 253252022
	Number of receive bytes: 268607352164
	Number of receive packet drops: 0
	Number of RX mbufs allocated from system pool: 0
	Number of system pool RX mbuf allocation failures: 0
	Number of empty EQ events: 0
	Number of no fragment errors: 0
	Number of rx_limit events: 15
	TCP segment aggregation large packets created: 15416158
	TCP packets aggregated into large packets: 104858101
	TCP payload bytes aggregated into large packets: 135967864882
	TCP segment aggregation average packets aggregated: 6
	TCP segment aggregation maximum packets aggregated: 105
Transmit statistics for TXQ number: 0
	Number of transmit packets: 208079618
	Number of transmit bytes: 184513255339
	Number of transmit packet drops: 0
	Number of transmit queue overflows: 0
	TCP segmentation offload packets transmitted: 1
	TCP segmentation offload maximum packet size: 1674
	Maximum entries used on this transmit queue: 174
Transmit statistics for TXQ number: 1
	Number of transmit packets: 174751382
	Number of transmit bytes: 181844280081
	Number of transmit packet drops: 0
	Number of transmit queue overflows: 0
	TCP segmentation offload packets transmitted: 0
	TCP segmentation offload maximum packet size: 0
	Maximum entries used on this transmit queue: 180
EOF
        @result = Netstat_v.new(text).result["ent0"]
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("00:00:c9:d9:d8:96")
  end
  it "parses the two column statistics ouutput" do
    expect(@result["Receive Statistics"]["Interrupts"]).to eq(157147159)
  end
  it "parses RXQ statistics" do
    expect(@result["Receive statistics for RXQ number"][0]["Number of receive interrupts"]).to eq(78848)
  end
end
