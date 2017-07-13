#
# Currently this is focused on networking.  Disks and other things
# will be added in later.
#
# A single web page will represent "the world" which will then contain
# things within it.  Each thing can be empty or not exist.
#
# The "world" will have these things:
#   1) CECs
#   2) Switches
#   3) IPSec tunnels
#   4) Other (HMCs?, etc)
#
# Switches and tunnels may be done later.  Currently the focus is on
# CECs (whole frames).
#
# A CEC will have a number of LPARs (1 or more) and, if needed,
# virtual switches.  A CEC could display the FSP and I suppose in
# theory it could display all the other goodies like the power
# supplies, etc but that is way off in the future if ever.
#
# A LPAR will be one of a few types:
#   1) A "real LPAR" will have only real Ethernet adapters.
#   2) A "VIO client" will have only VEAs (and no SEA).  I'll try to
#      not use "VIOC" because it is too easy to mistake it for a
#      VIOS.
#   3) A mixed client will have no SEA but will have both real and
#      virtual adapters.  These are the black sheep.
#   4) A VIOS which will have one or more SEA.

