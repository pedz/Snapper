
# Not needed if odm is in a lib.  Still undecided how I want to do
# this.
# $LOAD_PATH.unshift File.expand_path("../..", __FILE__)

TEST_SNAP = File.expand_path("../../test.snap", __FILE__)
TEST_TCPIP_SNAP = TEST_SNAP + "/tcpip/tcpip.snap"
TEST_NETSTAT_V = File.expand_path("../../All-Netstat.bz2", __FILE__)
TEST_DUMP_SNAP = TEST_SNAP + "/dump/dump.snap"

Top = self.class
