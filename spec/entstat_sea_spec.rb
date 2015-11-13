require "spec_helper"
require "netstat_v_sea"

describe Netstat_v_sea do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent22) :
Device Type: Shared Ethernet Adapter
Hardware Address: e4:1f:13:fd:29:75
Elapsed Time: 0 days 2 hours 52 minutes 41 seconds

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 359754                               Packets: 272450
Bytes: 2011436990                             Bytes: 22016683
Interrupts: 0                                 Interrupts: 183710
Transmit Errors: 0                            Receive Errors: 0
Packets Dropped: 0                            Packets Dropped: 0
                                              Bad Packets: 0
Max Packets on S/W Transmit Queue: 3         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Elapsed Time: 0 days 0 hours 0 minutes 0 seconds
Broadcast Packets: 1471                       Broadcast Packets: 1427
Multicast Packets: 631                        Multicast Packets: 5702
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
Adapter Data Rate: 0
Driver Flags: Up Broadcast Running 
	Simplex 64BitSupport ChecksumOffload 
	LargeSend DataRateSet 


--------------------------------------------------------------
Statistics for adapters in the Shared Ethernet Adapter ent22
--------------------------------------------------------------
Number of adapters: 2
SEA Flags: 00000013
    < THREAD >
    < LARGESEND >
    < LARGE_RECEIVE >
VLAN Ids :
    ent15: 300
    ent16: 3
Real Side Statistics:
    Packets received: 238619
    Packets bridged: 42757
    Packets consumed: 197732
    Packets fragmented: 0
    Packets transmitted: 241274
    Packets dropped: 0
    Packets filtered(VlanId): 0
    Packets filtered(Reserved address): 5087
Virtual Side Statistics:
    Packets received: 33781
    Packets bridged: 33773
    Packets consumed: 45
    Packets fragmented: 0
    Packets transmitted: 118459
    Packets dropped: 0
    Packets filtered(VlanId): 0
Other Statistics:
    Output packets generated: 210621
    Output packets dropped: 0
    Device output failures: 3
    Memory allocation failures: 0
    ICMP error packets sent: 0
    Non IP packets larger than MTU: 0
    Thread queue overflow packets: 0


	SEA THREADS INFORMATION

	Thread .............. #0
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 13280
    Queue max packets queued: 5

	Thread .............. #1
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 17688
    Queue max packets queued: 8

	Thread .............. #2
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 9137
    Queue max packets queued: 42

	Thread .............. #3
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 10362
    Queue max packets queued: 70

	Thread .............. #4
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 11255
    Queue max packets queued: 5

	Thread .............. #5
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 200098
    Queue max packets queued: 26

	Thread .............. #6
    SEA Default Queue #8 
    Queue full dropped packets: 0
    Queue packets queued: 0
    Queue average packets queued: 1
    Queue packets count: 10580
    Queue max packets queued: 5
High Availability Statistics:
    Control Channel PVID: 1300
    Control Packets in: 605
    Control Packets out: 44164
Type of Packets Received:
    Keep-Alive Packets: 456
    Recovery Packets: 0
    Notify Packets: 1
    Limbo Packets: 0
    State: PRIMARY
    Bridge Mode: All
    Number of Times Server became Backup: 1
    Number of Times Server became Primary: 1
    High Availability Mode: Auto
    Priority: 1
--------------------------------------------------------------
Real Adapter: ent2

EOF
    @result = Netstat_v.new(text, Hash.new).parse["ent22"]
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("e4:1f:13:fd:29:75")
  end

  it "parses the transmit packets as an integer" do
    expect(@result["Transmit Statistics"]["Packets"]).to eq(359754)
  end

  it "parses the receive bytes as an integer" do
    expect(@result["Receive Statistics"]["Bytes"]).to eq(22016683)
  end

  it "parses the Driver Flags as an array of strings" do
    expect(@result["Driver Flags"]).to eq(["Up",
                                           "Broadcast",
                                           "Running",
                                           "Simplex",
                                           "64BitSupport",
                                           "ChecksumOffload",
                                           "LargeSend",
                                           "DataRateSet"])
  end

  it "parses SEA Flags (hex)" do
    expect(@result["SEA Flags (hex)"]).to eq(19)
  end

  it "parses SEA Flags" do
    expect(@result["SEA Flags"]).to eq(["THREAD",
                                        "LARGESEND",
                                        "LARGE_RECEIVE"])
  end

  it "parses VLAN Ids" do
    expect(@result["VLAN Ids"]["ent15"]).to eq([ 300 ])
  end

  it "parses Real Side Statistics" do
    expect(@result["Real Side Statistics"]["Packets transmitted"]).to eq(241274)
  end
end
