require "spec_helper"
require "entstat_fibre"

describe EntstatFibre do
  context "df1000f114108a0" do
    before(:context) {
      text = <<EOF
FIBRE CHANNEL STATISTICS REPORT: fcs3

Device Type: FC Adapter (adapter/pciex/df1000f114108a0)
Serial Number: 1A203001E4
Option ROM Version: 02782037
ZA: U2D2.00X7 
World Wide Node Name: 0x20000000C9D660FA
World Wide Port Name: 0x10000000C9D660FA

FC-4 TYPES:
  Supported: 0x0000012000000000000000000000000000000000000000000000000000000000
  Active:    0x0000010000000000000000000000000000000000000000000000000000000000

FC-4 TYPES (ULP mappings):
  Supported ULPs:   
    	Internet Protocol (IP) over Fibre Channel (IETF RFC2625) 
    	Small Computer System Interface (SCSI) Fibre Channel Protocol (FCP)
  Active ULPs:   
    	Small Computer System Interface (SCSI) Fibre Channel Protocol (FCP)
Class of Service: 3
Port Speed (supported): 8 GBIT
Port Speed (running):   8 GBIT
Port FC ID: 0x21EE40
Port Type: Fabric

Seconds Since Last Reset: 10364           

	Transmit Statistics	Receive Statistics
	-------------------	------------------
Frames: 180323917       	358920289       
Words:  80956662528     	167760228608    

LIP Count: 0               
NOS Count: 0               
Error Frames:  1               
Dumped Frames: 0               
Link Failure Count: 0               
Loss of Sync Count: 4               
Loss of Signal: 0               
Primitive Seq Protocol Error Count: 0               
Invalid Tx Word Count: 15              
Invalid CRC Count: 1               

IP over FC Adapter Driver Information
  No DMA Resource Count: 0               
  No Adapter Elements Count: 0               

IP over FC Traffic Statistics
  Input Requests:   0               
  Output Requests:  0               
  Control Requests: 0               
  Input Bytes:  0               
  Output Bytes: 0               

Adapter Effective max transfer value:   0x100000
EOF
      @result = NetstatV.new(text, Hash.new).parse["fcs3"]
    }

    # Note, the sample used above is incorrect.  The 2nd section with
    # 'No DMA Resource Count: 0' should have been grepped out as well as
    # the second section with "Input Requests:".  This may eventually
    # cause grief with duplicate values.
    it "parses the serial number" do
      expect(@result["Serial Number"]).to eq("1A203001E4")
    end
    it "parses World Wide Node Name" do
      expect(@result["World Wide Node Name"]).to eq("0x20000000C9D660FA")
    end
    it "parses the transmit statistics" do
      expect(@result["Transmit Statistics"]["Frames"]).to eq(180323917)
    end
    it "parses the IP over FC Adapter Driver Information" do
      expect(@result["IP over FC Adapter Driver Information"]["No DMA Resource Count"]).to eq(0)
    end
  end

  context "IBM,vfc-client" do
    before(:context) {
      text = <<EOF
FIBRE CHANNEL STATISTICS REPORT: fcs0

Device Type: FC Adapter (adapter/vdevice/IBM,vfc-client)
Serial Number: UNKNOWN
Option ROM Version: UNKNOWN
ZA: UNKNOWN
World Wide Node Name: 0xC05076053FEF003C
World Wide Port Name: 0xC05076053FEF003C

FC-4 TYPES:
  Supported: 0x0000010000000000000000000000000000000000000000000000000000000000
  Active:    0x0000010000000000000000000000000000000000000000000000000000000000

FC-4 TYPES (ULP mappings):
  Supported ULPs:   
    	Small Computer System Interface (SCSI) Fibre Channel Protocol (FCP)
  Active ULPs:   
    	Small Computer System Interface (SCSI) Fibre Channel Protocol (FCP)
Class of Service: 3
Port Speed (supported): UNKNOWN
Port Speed (running):   8 GBIT
Port FC ID: 0x014407
Port Type: Fabric

Seconds Since Last Reset: 0               

	Transmit Statistics	Receive Statistics
	-------------------	------------------
Frames: 0               	0               
Words:  0               	0               

LIP Count: 0               
NOS Count: 0               
Error Frames:  0               
Dumped Frames: 0               
Link Failure Count: 0               
Loss of Sync Count: 0               
Loss of Signal: 0               
Primitive Seq Protocol Error Count: 0               
Invalid Tx Word Count: 0               
Invalid CRC Count: 0               

IP over FC Adapter Driver Information
  No DMA Resource Count: 0               
  No Adapter Elements Count: 0               

IP over FC Traffic Statistics
  Input Requests:   0               
  Output Requests:  0               
  Control Requests: 0               
  Input Bytes:  0               
  Output Bytes: 0               

Adapter Effective max transfer value:   0x100000
EOF
      @result = NetstatV.new(text, Hash.new).parse["fcs0"]
    }
    
    it "parses the serial number" do
      expect(@result["Serial Number"]).to eq("UNKNOWN")
    end
    it "parses World Wide Node Name" do
      expect(@result["World Wide Node Name"]).to eq("0xC05076053FEF003C")
    end
    it "parses the transmit statistics" do
      expect(@result["Transmit Statistics"]["Frames"]).to eq(0)
    end
    it "parses the IP over FC Adapter Driver Information" do
      expect(@result["IP over FC Adapter Driver Information"]["No DMA Resource Count"]).to eq(0)
    end
  end

  context "7710018077107f0" do
    before(:context) {
      text = <<EOF
FIBRE CHANNEL STATISTICS REPORT: fcs0

Device Type: FC Adapter (adapter/pciex/7710018077107f0)
Serial Number: 11S42C1831YK5122217GYP
Option ROM Version: 0313050700

World Wide Node Name: 0x200000C0DD1E0C01
World Wide Port Name: 0x210000C0DD1E0C01

FC-4 TYPES:
  Supported: 0x0000010000000000000000000000000000000000000000000000000000000000
  Active:    0x0000010000000000000000000000000000000000000000000000000000000000

FC-4 TYPES (ULP mappings):
  Supported ULPs:   
    	Small Computer System Interface (SCSI) Fibre Channel Protocol (FCP)
  Active ULPs:   
    	Small Computer System Interface (SCSI) Fibre Channel Protocol (FCP)
Class of Service: 3
Port Speed (supported): 10 GBIT
Port Speed (running):   10 GBIT
Port FC ID: 0x380476
Port Type: Fabric
Attention Type:   Link Up
Topology:  Point to Point or Fabric

Seconds Since Last Reset: 5327            

	Transmit Statistics	Receive Statistics
	-------------------	------------------
Frames: 1440907         	1639466         
Words:  0               	0               

LIP Count: 0               
NOS Count: 0               
Error Frames:  0               
Dumped Frames: 0               
Link Failure Count: 0               
Loss of Sync Count: 0               
Loss of Signal: 0               
Primitive Seq Protocol Error Count: 0               
Invalid Tx Word Count: 0               
Invalid CRC Count: 0               

IP over FC Adapter Driver Information
  No DMA Resource Count: 0               
  No Adapter Elements Count: 0               

IP over FC Traffic Statistics
  Input Requests:   0               
  Output Requests:  0               
  Control Requests: 0               
  Input Bytes:  0               
  Output Bytes: 0               

Adapter Effective max transfer value:   0x100000

EOF
      @result = NetstatV.new(text, Hash.new).parse["fcs0"]
    }
    
    it "parses the serial number" do
      expect(@result["Serial Number"]).to eq("11S42C1831YK5122217GYP")
    end
    it "parses World Wide Node Name" do
      expect(@result["World Wide Node Name"]).to eq("0x200000C0DD1E0C01")
    end
    it "parses the transmit statistics" do
      expect(@result["Transmit Statistics"]["Frames"]).to eq(1440907)
    end
    it "parses the IP over FC Adapter Driver Information" do
      expect(@result["IP over FC Adapter Driver Information"]["No DMA Resource Count"]).to eq(0)
    end
  end
end
