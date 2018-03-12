require "spec_helper"
require "lsvirt_out_parser"
require "db"

describe LsvirtOutParser do
  describe "#parse" do
    before(:context) do
      @db = Db.new
      @text = <<'HERE'
SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost0          U8408.E8E.78CB04W-V1-C81                     0x00000003

VTD                   tstc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk32
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L1E000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost1          U8408.E8E.78CB04W-V1-C101                    0x00000004

VTD                   a1pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk2
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L0
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost2          U8408.E8E.78CB04W-V1-C102                    0x00000005

VTD                   a2pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk31
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L1D000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost3          U8408.E8E.78CB04W-V1-C103                    0x00000006

VTD                   c1pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk9
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L7000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost4          U8408.E8E.78CB04W-V1-C104                    0x00000007

VTD                   e1pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk11
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L9000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost5          U8408.E8E.78CB04W-V1-C105                    0x00000008

VTD                   e1pa1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk10
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L8000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost6          U8408.E8E.78CB04W-V1-C106                    0x00000009

VTD                   i1pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk14
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-LC000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost7          U8408.E8E.78CB04W-V1-C107                    0x0000000a

VTD                   i1pa1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk13
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-LB000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost8          U8408.E8E.78CB04W-V1-C108                    0x0000000b

VTD                   d3pl1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk12
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-LA000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost9          U8408.E8E.78CB04W-V1-C109                    0x0000000c

VTD                   k1pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk15
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-LD000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost10         U8408.E8E.78CB04W-V1-C110                    0x0000000d

VTD                   p2pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk21
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L13000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost11         U8408.E8E.78CB04W-V1-C111                    0x0000000e

VTD                   p2pa1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk20
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L12000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost12         U8408.E8E.78CB04W-V1-C112                    0x0000000f

VTD                   d2pl1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk19
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L11000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost13         U8408.E8E.78CB04W-V1-C113                    0x00000010

VTD                   s2pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk23
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L15000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost14         U8408.E8E.78CB04W-V1-C114                    0x00000011

VTD                   w1pc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk27
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L19000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost15         U8408.E8E.78CB04W-V1-C115                    0x00000012

VTD                   w1pa1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk26
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L18000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost16         U8408.E8E.78CB04W-V1-C116                    0x00000013

VTD                   d4pl1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk25
Physloc               U78CD.001.FZHG310-P1-C6-T1-W50060E8013350012-L17000000000000
Mirrored              false

SVSA            Physloc                                      Client Partition ID
--------------- -------------------------------------------- ------------------
vhost17         U8408.E8E.78CB04W-V1-C117                    0x00000014

VTD                   vcsc1srvg
Status                Available
LUN                   0x8100000000000000
Backing device        hdisk37
Physloc               U78C7.001.KIC2632-P1-C6-T1-W50060E8013350002-L23000000000000
Mirrored              false

SVEA   Physloc
------ --------------------------------------------
ent4   U8408.E8E.78CB04W-V1-C2-T1

SEA                   ent5
Backing device        ent1
Status                Available
Physloc               U78C7.001.KIC2632-P1-C11-T2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver0   U8408.E8E.78CB04W-V1-C32897             3 tstc1s         AIX

Backing device:ent6
Status:Available
Physloc:U78CD.001.FZHG310-P1-C1-T1-S1
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V3-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver1   U8408.E8E.78CB04W-V1-C32898            90 SVUSPh21P      AIX

Backing device:ent7
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S45
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V90-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver2   U8408.E8E.78CB04W-V1-C32899             3 tstc1s         AIX

Backing device:ent8
Status:Available
Physloc:U78CD.001.FZHG310-P1-C1-T4-S3
Client device name:ent2
Client device physloc:U8408.E8E.78CB04W-V3-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver3   U8408.E8E.78CB04W-V1-C32900             4 a1pc1s         AIX

Backing device:ent9
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T3-S15
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V4-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver4   U8408.E8E.78CB04W-V1-C32901             4 a1pc1s         AIX

Backing device:ent10
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S16
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V4-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver5   U8408.E8E.78CB04W-V1-C32902             5 a2pc1s         AIX

Backing device:ent11
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S20
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V5-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver6   U8408.E8E.78CB04W-V1-C32903             5 a2pc1s         AIX

Backing device:ent12
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S21
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V5-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver7   U8408.E8E.78CB04W-V1-C32904             5 N/A            N/A

Backing device:ent13
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S47
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V5-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver8   U8408.E8E.78CB04W-V1-C32905             6 c1pc1s         AIX

Backing device:ent14
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S9
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V6-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver9   U8408.E8E.78CB04W-V1-C32906             6 c1pc1s         AIX

Backing device:ent15
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S10
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V6-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver10  U8408.E8E.78CB04W-V1-C32907             6 c1pc1s         AIX

Backing device:ent16
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S11
Client device name:ent2
Client device physloc:U8408.E8E.78CB04W-V6-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver11  U8408.E8E.78CB04W-V1-C32908             7 e1pc1s         AIX

Backing device:ent17
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S12
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V7-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver12  U8408.E8E.78CB04W-V1-C32909             7 e1pc1s         AIX

Backing device:ent18
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S13
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V7-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver13  U8408.E8E.78CB04W-V1-C32910             7 N/A            N/A

Backing device:ent19
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S14
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V7-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver14  U8408.E8E.78CB04W-V1-C32911             8 e1pa1s         AIX

Backing device:ent20
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S1
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V8-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver15  U8408.E8E.78CB04W-V1-C32912             8 e1pa1s         AIX

Backing device:ent21
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S2
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V8-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver16  U8408.E8E.78CB04W-V1-C32913             9 i1pc1s         AIX

Backing device:ent22
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S17
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V9-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver17  U8408.E8E.78CB04W-V1-C32914             9 i1pc1s         AIX

Backing device:ent23
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S18
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V9-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver18  U8408.E8E.78CB04W-V1-C32915             9 i1pc1s         AIX

Backing device:ent24
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S19
Client device name:ent2
Client device physloc:U8408.E8E.78CB04W-V9-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver19  U8408.E8E.78CB04W-V1-C32916            10 i1pa1s         AIX

Backing device:ent25
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S3
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V10-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver20  U8408.E8E.78CB04W-V1-C32917            10 i1pa1s         AIX

Backing device:ent26
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S46
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V10-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver21  U8408.E8E.78CB04W-V1-C32918            11 d3pl1s         AIX

Backing device:ent27
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T3-S22
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V11-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver22  U8408.E8E.78CB04W-V1-C32919            11 d3pl1s         AIX

Backing device:ent28
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S23
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V11-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver23  U8408.E8E.78CB04W-V1-C32920            12 k1pc1s         AIX

Backing device:ent29
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S24
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V12-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver24  U8408.E8E.78CB04W-V1-C32921            12 k1pc1s         AIX

Backing device:ent30
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S25
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V12-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver25  U8408.E8E.78CB04W-V1-C32922            12 N/A            N/A

Backing device:ent31
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S26
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V12-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver26  U8408.E8E.78CB04W-V1-C32923            13 p2pc1s         AIX

Backing device:ent32
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S27
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V13-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver27  U8408.E8E.78CB04W-V1-C32924            13 p2pc1s         AIX

Backing device:ent33
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S28
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V13-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver28  U8408.E8E.78CB04W-V1-C32925            13 p2pc1s         AIX

Backing device:ent34
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S29
Client device name:ent2
Client device physloc:U8408.E8E.78CB04W-V13-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver29  U8408.E8E.78CB04W-V1-C32926            14 p2pa1s         AIX

Backing device:ent35
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S30
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V14-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver30  U8408.E8E.78CB04W-V1-C32927            14 p2pa1s         AIX

Backing device:ent36
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S31
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V14-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver31  U8408.E8E.78CB04W-V1-C32928            15 d2pl1s         AIX

Backing device:ent37
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T3-S32
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V15-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver32  U8408.E8E.78CB04W-V1-C32929            15 N/A            N/A

Backing device:ent38
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S33
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V15-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver33  U8408.E8E.78CB04W-V1-C32930            16 s2pc1s         AIX

Backing device:ent39
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S34
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V16-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver34  U8408.E8E.78CB04W-V1-C32931            16 s2pc1s         AIX

Backing device:ent40
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S35
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V16-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver35  U8408.E8E.78CB04W-V1-C32932            16 N/A            N/A

Backing device:ent41
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S36
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V16-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver36  U8408.E8E.78CB04W-V1-C32933            17 w1pc1s         AIX

Backing device:ent42
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S37
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V17-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver37  U8408.E8E.78CB04W-V1-C32934            17 w1pc1s         AIX

Backing device:ent43
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S38
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V17-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver38  U8408.E8E.78CB04W-V1-C32935            17 w1pc1s         AIX

Backing device:ent44
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S39
Client device name:ent2
Client device physloc:U8408.E8E.78CB04W-V17-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver39  U8408.E8E.78CB04W-V1-C32936            18 w1pa1s         AIX

Backing device:ent45
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T1-S40
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V18-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver40  U8408.E8E.78CB04W-V1-C32937            18 w1pa1s         AIX

Backing device:ent46
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S41
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V18-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver41  U8408.E8E.78CB04W-V1-C32938            19 d4pl1s         AIX

Backing device:ent47
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T3-S42
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V19-C2

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver42  U8408.E8E.78CB04W-V1-C32939            19 N/A            N/A

Backing device:ent48
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T4-S43
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V19-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver43  U8408.E8E.78CB04W-V1-C32940             3 N/A            N/A

Backing device:ent49
Status:Available
Physloc:U78C7.001.KIC2632-P1-C9-T4-S3
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V3-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver44  U8408.E8E.78CB04W-V1-C32941             3 tstc1s         AIX

Backing device:ent50
Status:Available
Physloc:U78CD.001.FZHG310-P2-C1-T2-S44
Client device name:ent1
Client device physloc:U8408.E8E.78CB04W-V3-C3

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver45  U8408.E8E.78CB04W-V1-C32942            98 SPgold72       AIX

Backing device:ent51
Status:Available
Physloc:U78CD.001.FZHG310-P1-C1-T1-S4
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V98-C3

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver46  U8408.E8E.78CB04W-V1-C32943            20 vcsc1s         AIX

Backing device:ent52
Status:Available
Physloc:U78CD.001.FZHG310-P1-C1-T1-S10
Client device name:ent0
Client device physloc:U8408.E8E.78CB04W-V20-C10

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver47  U8408.E8E.78CB04W-V1-C32944            20 N/A            N/A

Backing device:ent53
Status:Available
Physloc:U78C7.001.KIC2632-P1-C3-T2-S5
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V20-C11

Name          Physloc                            ClntID ClntName       ClntOS 
------------- ---------------------------------- ------ -------------- -------
vnicserver48  U8408.E8E.78CB04W-V1-C32945            20 N/A            N/A

Backing device:ent54
Status:Available
Physloc:U78CD.001.FZHG310-P1-C1-T4-S11
Client device name:N/A
Client device physloc:U8408.E8E.78CB04W-V20-C12

name             status      description
ent4             Available   Virtual I/O Ethernet Adapter (l-lan)
vasi0            Available   Virtual Asynchronous Services Interface (VASI)
vbsd0            Available   Virtual Block Storage Device (VBSD)
vfchost0         Available   Virtual FC Server Adapter
vfchost1         Available   Virtual FC Server Adapter
vfchost2         Available   Virtual FC Server Adapter
vfchost3         Available   Virtual FC Server Adapter
vfchost4         Available   Virtual FC Server Adapter
vfchost5         Available   Virtual FC Server Adapter
vfchost6         Available   Virtual FC Server Adapter
vfchost7         Available   Virtual FC Server Adapter
vfchost8         Available   Virtual FC Server Adapter
vfchost9         Available   Virtual FC Server Adapter
vfchost10        Available   Virtual FC Server Adapter
vfchost11        Available   Virtual FC Server Adapter
vfchost12        Available   Virtual FC Server Adapter
vfchost13        Available   Virtual FC Server Adapter
vfchost14        Available   Virtual FC Server Adapter
vfchost15        Available   Virtual FC Server Adapter
vfchost16        Available   Virtual FC Server Adapter
vfchost17        Available   Virtual FC Server Adapter
vfchost18        Available   Virtual FC Server Adapter
vfchost19        Available   Virtual FC Server Adapter
vfchost20        Available   Virtual FC Server Adapter
vfchost21        Available   Virtual FC Server Adapter
vfchost22        Available   Virtual FC Server Adapter
vfchost23        Available   Virtual FC Server Adapter
vfchost24        Available   Virtual FC Server Adapter
vfchost25        Available   Virtual FC Server Adapter
vfchost26        Available   Virtual FC Server Adapter
vfchost27        Available   Virtual FC Server Adapter
vfchost28        Available   Virtual FC Server Adapter
vfchost29        Available   Virtual FC Server Adapter
vfchost30        Available   Virtual FC Server Adapter
vfchost31        Available   Virtual FC Server Adapter
vfchost32        Available   Virtual FC Server Adapter
vfchost33        Available   Virtual FC Server Adapter
vfchost34        Available   Virtual FC Server Adapter
vfchost35        Available   Virtual FC Server Adapter
vfchost38        Available   Virtual FC Server Adapter
vfchost39        Available   Virtual FC Server Adapter
vhost0           Available   Virtual SCSI Server Adapter
vhost1           Available   Virtual SCSI Server Adapter
vhost2           Available   Virtual SCSI Server Adapter
vhost3           Available   Virtual SCSI Server Adapter
vhost4           Available   Virtual SCSI Server Adapter
vhost5           Available   Virtual SCSI Server Adapter
vhost6           Available   Virtual SCSI Server Adapter
vhost7           Available   Virtual SCSI Server Adapter
vhost8           Available   Virtual SCSI Server Adapter
vhost9           Available   Virtual SCSI Server Adapter
vhost10          Available   Virtual SCSI Server Adapter
vhost11          Available   Virtual SCSI Server Adapter
vhost12          Available   Virtual SCSI Server Adapter
vhost13          Available   Virtual SCSI Server Adapter
vhost14          Available   Virtual SCSI Server Adapter
vhost15          Available   Virtual SCSI Server Adapter
vhost16          Available   Virtual SCSI Server Adapter
vhost17          Available   Virtual SCSI Server Adapter
vnicserver0      Available   Virtual NIC Server Device (vnicserver)
vnicserver1      Available   Virtual NIC Server Device (vnicserver)
vnicserver2      Available   Virtual NIC Server Device (vnicserver)
vnicserver3      Available   Virtual NIC Server Device (vnicserver)
vnicserver4      Available   Virtual NIC Server Device (vnicserver)
vnicserver5      Available   Virtual NIC Server Device (vnicserver)
vnicserver6      Available   Virtual NIC Server Device (vnicserver)
vnicserver7      Available   Virtual NIC Server Device (vnicserver)
vnicserver8      Available   Virtual NIC Server Device (vnicserver)
vnicserver9      Available   Virtual NIC Server Device (vnicserver)
vnicserver10     Available   Virtual NIC Server Device (vnicserver)
vnicserver11     Available   Virtual NIC Server Device (vnicserver)
vnicserver12     Available   Virtual NIC Server Device (vnicserver)
vnicserver13     Available   Virtual NIC Server Device (vnicserver)
vnicserver14     Available   Virtual NIC Server Device (vnicserver)
vnicserver15     Available   Virtual NIC Server Device (vnicserver)
vnicserver16     Available   Virtual NIC Server Device (vnicserver)
vnicserver17     Available   Virtual NIC Server Device (vnicserver)
vnicserver18     Available   Virtual NIC Server Device (vnicserver)
vnicserver19     Available   Virtual NIC Server Device (vnicserver)
vnicserver20     Available   Virtual NIC Server Device (vnicserver)
vnicserver21     Available   Virtual NIC Server Device (vnicserver)
vnicserver22     Available   Virtual NIC Server Device (vnicserver)
vnicserver23     Available   Virtual NIC Server Device (vnicserver)
vnicserver24     Available   Virtual NIC Server Device (vnicserver)
vnicserver25     Available   Virtual NIC Server Device (vnicserver)
vnicserver26     Available   Virtual NIC Server Device (vnicserver)
vnicserver27     Available   Virtual NIC Server Device (vnicserver)
vnicserver28     Available   Virtual NIC Server Device (vnicserver)
vnicserver29     Available   Virtual NIC Server Device (vnicserver)
vnicserver30     Available   Virtual NIC Server Device (vnicserver)
vnicserver31     Available   Virtual NIC Server Device (vnicserver)
vnicserver32     Available   Virtual NIC Server Device (vnicserver)
vnicserver33     Available   Virtual NIC Server Device (vnicserver)
vnicserver34     Available   Virtual NIC Server Device (vnicserver)
vnicserver35     Available   Virtual NIC Server Device (vnicserver)
vnicserver36     Available   Virtual NIC Server Device (vnicserver)
vnicserver37     Available   Virtual NIC Server Device (vnicserver)
vnicserver38     Available   Virtual NIC Server Device (vnicserver)
vnicserver39     Available   Virtual NIC Server Device (vnicserver)
vnicserver40     Available   Virtual NIC Server Device (vnicserver)
vnicserver41     Available   Virtual NIC Server Device (vnicserver)
vnicserver42     Available   Virtual NIC Server Device (vnicserver)
vnicserver43     Available   Virtual NIC Server Device (vnicserver)
vnicserver44     Available   Virtual NIC Server Device (vnicserver)
vnicserver45     Available   Virtual NIC Server Device (vnicserver)
vnicserver46     Available   Virtual NIC Server Device (vnicserver)
vnicserver47     Available   Virtual NIC Server Device (vnicserver)
vnicserver48     Available   Virtual NIC Server Device (vnicserver)
vsa0             Available   LPAR Virtual Serial Adapter
a1pc1srvg        Available   Virtual Target Device - Disk
a2pc1srvg        Available   Virtual Target Device - Disk
c1pc1srvg        Available   Virtual Target Device - Disk
d2pl1srvg        Available   Virtual Target Device - Disk
d3pl1srvg        Available   Virtual Target Device - Disk
d4pl1srvg        Available   Virtual Target Device - Disk
e1pa1srvg        Available   Virtual Target Device - Disk
e1pc1srvg        Available   Virtual Target Device - Disk
i1pa1srvg        Available   Virtual Target Device - Disk
i1pc1srvg        Available   Virtual Target Device - Disk
k1pc1srvg        Available   Virtual Target Device - Disk
p2pa1srvg        Available   Virtual Target Device - Disk
p2pc1srvg        Available   Virtual Target Device - Disk
s2pc1srvg        Available   Virtual Target Device - Disk
tstc1srvg        Available   Virtual Target Device - Disk
vcsc1srvg        Available   Virtual Target Device - Disk
w1pa1srvg        Available   Virtual Target Device - Disk
w1pc1srvg        Available   Virtual Target Device - Disk
ent5             Available   Shared Ethernet Adapter
pkcs11           Available   ACF/PKCS#11 Device
HERE
      LsvirtOutParser.new(StringIO.new(@text), @db).parse
    end

    it "creates an LsvirtOut item" do
      a = @db["LsvirtOut"]
      expect(a.length).to eq(68)
    end

    it "parses vnicserver entries correctly" do
      expect(@db["LsvirtOut"].map { |a| a[:vnic] }).to include("vnicserver0")
    end
  end
end
