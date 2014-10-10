require "spec_helper"
require "netstat_v_vioent"

describe Netstat_v_vioent do 
  before(:all) {
    text = <<EOF
ETHERNET STATISTICS (ent4) :
Device Type: Virtual I/O Ethernet Adapter (l-lan)
Hardware Address: 0a:94:38:bd:2b:0c

Transmit Statistics:                          Receive Statistics:
--------------------                          -------------------
Packets: 38487896717                          Packets: 42181793906
Bytes: 8176832197522                          Bytes: 58363966969519
Interrupts: 0                                 Interrupts: 24194907104
Transmit Errors: 312738086                    Receive Errors: 0
Packets Dropped: 312738102                    Packets Dropped: 0
                                              Bad Packets: 0

Max Packets on S/W Transmit Queue: 0         
S/W Transmit Queue Overflow: 0
Current S/W+H/W Transmit Queue Length: 0

Broadcast Packets: 311828256                  Broadcast Packets: 242426
Multicast Packets: 251529660                  Multicast Packets: 68831
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
Adapter Data Rate: 20000
Driver Flags: Up Broadcast Running 
	Simplex Promiscuous AllMulticast 
	64BitSupport ChecksumOffload DataRateSet 

Virtual I/O Ethernet Adapter (l-lan) Specific Statistics:
---------------------------------------------------------
RQ Length: 4481
Trunk Adapter: True
  Priority: 1  Active: True
Filter MCast Mode: False
Filters: 255
  Enabled: 2  Queued: 0  Overflow: 0
LAN State: Operational

Hypervisor Send Failures: 3504348
  Receiver Failures: 3504348
  Send Errors: 0
Hypervisor Receive Failures: 0

Invalid VLAN ID Packets: 312738106

ILLAN Attributes: 0000000000003103 [0000000000003103]

Port VLAN ID:  4093
VLAN Tag IDs:   205   298   299  1510  1600  1601  3520  3521  3551
               3552  3820  3832

Switch ID: vSwitch2

Hypervisor Information  
  Virtual Memory        
    Total (KB)                 79
  I/O Memory            
    VRM Minimum (KB)          100
    VRM Desired (KB)          100
    DMA Max Min (KB)          128

Transmit Information    
  Transmit Buffers       
    Buffer Size             65536
    Buffers                    32
    History             
      No Buffers                0
  Virtual Memory        
    Total (KB)               2048
  I/O Memory            
    VRM Minimum (KB)         2176
    VRM Desired (KB)        16384
    DMA Max Min (KB)        16384

Receive Information     
  Receive Buffers        
    Buffer Type              Tiny    Small   Medium    Large     Huge
    Min Buffers               512      512      128       24       24
    Max Buffers              2048     2048      256       64       64
    Allocated                 512      512      128       24       24
    Registered                511      511      128       24       24
    History             
      Max Allocated           512      791      128       24       24
      Lowest Registered       505      502      128       24       24
  Virtual Memory        
    Minimum (KB)              256     1024     2048      768     1536
    Maximum (KB)             1024     4096     4096     2048     4096
  I/O Memory            
    VRM Minimum (KB)         4096     4096     2560      864     1632
    VRM Desired (KB)        16384    16384     5120     2304     4352
    DMA Max Min (KB)        16384    16384     8192     4096     8192

I/O Memory Information  
  Total VRM Minimum (KB)    15524
  Total VRM Desired (KB)    61028
  Total DMA Max Min (KB)    69760

EOF
    @result = Netstat_v.new(text).result["ent4"]
  }
  it "parses the hardware MAC address" do
    expect(@result["Hardware Address"]).to eq("0a:94:38:bd:2b:0c")
  end
  it "parsers the transmit packets as an integer" do
    expect(@result["Transmit Statistics"]["Packets"]).to eq(38487896717)
  end
  it "parsers the receive bytes as an integer" do
    expect(@result["Receive Statistics"]["Bytes"]).to eq(58363966969519)
  end
  it "parses the Driver Flags as an array of strings" do
    expect(@result["Driver Flags"]).to eq(["Up",
                                         "Broadcast",
                                         "Running",
                                         "Simplex",
                                         "Promiscuous",
                                         "AllMulticast",
                                         "64BitSupport", 
                                         "ChecksumOffload",
                                         "DataRateSet"])
  end
  it "parses 'Current HW Transmit Queue Length' under the Transmit Statistics" do
    expect(@result["Transmit Statistics"]["Current HW Transmit Queue Length"]).to eq(0)
  end
  it "parses the Hypervisor Information correctly" do
    expect(@result["Hypervisor Information"]["Virtual Memory"]["Total (KB)"]).to eq(79)
  end
  it "parses the Transmit Information correctly" do
    expect(@result["Transmit Information"]["Transmit Buffers"]["Buffer Size"]).to eq(65536)
  end
  it "parses the Receive Information Receive Buffers correctly" do
    expect(@result["Receive Information"]["Receive Buffers"]["Tiny"]["Min Buffers"]).to eq(512)
  end
  it "parses the Receive Information Receive Buffers History correctly" do
    expect(@result["Receive Information"]["Receive Buffers"]["Huge"]["History"]["Max Allocated"]).to eq(24)
  end
  it "parses the Receive Information Virtual Memory correctly" do
    expect(@result["Receive Information"]["Virtual Memory"]["Medium"]["Minimum (KB)"]).to eq(2048)
  end
  it "parses the Receive Information I/O Memory correctly" do
    expect(@result["Receive Information"]["I/O Memory"]["Small"]["DMA Max Min (KB)"]).to eq(16384)
  end
  it "parses the I/O Memory Information correctly" do
    expect(@result["I/O Memory Information"]["Total VRM Minimum (KB)"]).to eq(15524)
  end
end
