require_relative 'logging'
require_relative 'item'

# Created run Devices.create runs.  The keys within a Device entry
# include:
#
# [cu_dv]      The CuDv entry for this device
#
# [cu_at]      The list of CuAt entries (customized attributes) for
#              this device.
#
# [pd_dv]      The PdDv entry if the PdDv is in the snap.
#
# [pd_at]      The list of PdAt entries of they are in the snap.
#
# [lsattr]     The parsed output of lsattr -El foo usually found in
#              general.snap
#
# [attributes] An Item whose keys are the attribute names.  The value
#              is also an Item.  If the snap includes the PdAt for
#              this device plus attribute pair, then the keys include
#              the fields from the PdAt entry.  Namely:
#
#              [attribute]  The name of the attribute.
#
#              [uniquetype] The uniquetype for the device the
#                           attribute belongs to.
#
#              [deflt]      The default value for the attribute.
#
#              [values]     The set of accepted values for this
#                           attribute.
#
#              [width]      The width of the attribute (I can't recall
#                           what this is used for.
#
#              [type]       The type of the attribute.
#
#              [generic]    The generic attribute flags.
#
#              [rep]        Attribute representation flags.
#
#              [nls_index]  nls index for the attribute.
#
#              [value]      Assumed to be the default value unless the
#                           CuAt entry is found.
#           
#              If the CuAt entry exists, then it will also contain the
#              fields from it.  Namely:
#
#              [name]       Matches the logical device name
#
#              [attribute]  The name of the attribute.
#
#              [value]      The customized value.
#
#              [type]       The type of the attribute.
#
#              [generic]    The generic attribute flags.
#
#              [rep]        The attribute representation flags.
#
#              [nls_index]  The nls index for the attribute.
#
# [errpt]      The list of error log entries found in errpt.out for
#              this device (matching the Resource Name in the error
#              log entry to the logical name for the device.
#
# [entstat]    The parsed entstat -d for this device usually found in
#              tcpip/tcpip.snap. 
#
# [netstat_in] If the device is an interface, the parsed piece of
#              netstat -in for this device usually found in
#              tcpip/tcpip.snap
#
# Note that all of these attributes may or may not be defined and they
# may be defined but with a nil value.  If the various pieces are in
# the snap, they will be hooked up but if they are not, then they
# won't be faked.
#
# Since all of these are of type Item, the dot notation can be used.
# For example if you know that item is a Sea, then you can get the
# list of virtual adapters with: +item.attributes.virt_adapters.value+
class Device < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
