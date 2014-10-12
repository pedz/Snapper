require "spec_helper"
require "netstat_v_ethchan"

describe Netstat_v_ethchan do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent20) :
Device Type: EtherChannel
Hardware Address: 00:00:c9:d9:d8:96

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 615469971                            Packets: 777899301
Bytes: 530889528330                           Bytes: 751885396976
Interrupts: 0                                 Interrupts: 262119457
Transmit Errors: 0                            Receive Errors: 842400
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0

Max Packets on S/W Transmit Queue: 412       
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 12

Broadcast Packets: 522                        Broadcast Packets: 109634
Multicast Packets: 33                         Multicast Packets: 181566
No Carrier Sense: 0                           CRC Errors: 0
DMA Underrun: 0                               DMA Overrun: 842400
Lost CTS Errors: 0                            Alignment Errors: 0
Max Collision Errors: 0                       No Resource Errors: 0
Late Collision Errors: 0                      Receive Collision Errors: 0
Deferred: 0                                   Packet Too Short Errors: 0
SQE Test: 0                                   Packet Too Long Errors: 0
Timeout Errors: 0                             Packets Discarded by Adapter: 0
Single Collision Count: 0                     Receiver Start Count: 0
Multiple Collision Count: 0
Current HW Transmit Queue Length: 12

General Statistics:
-------------------
No mbuf Errors: 0
Adapter Reset Count: 0
Adapter Data Rate: 20000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous 64BitSupport 
	ChecksumOffload LargeSend DataRateSet 

=============================================================
=============================================================

Statistics for every adapter in the EtherChannel:
-------------------------------------------------

Number of adapters: 2
Operating mode: Standard mode
Hash mode: Destination IP address

-------------------------------------------------------------

EOF
    @result = Netstat_v.new(text).result["ent20"]
  }

  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("00:00:c9:d9:d8:96")
  end

  it "parses the transmit packets as an integer" do
    expect(@result["Transmit Statistics"]["Packets"]).to eq(615469971)
  end

  it "parses the receive bytes as an integer" do
    expect(@result["Receive Statistics"]["Bytes"]).to eq(751885396976)
  end

  it "parses the Driver Flags as an array of strings" do
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

  it "parses Operating mode" do
    expect(@result["Operating mode"]).to eq("Standard mode")
  end
end
