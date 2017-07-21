require_relative 'device'
require_relative 'logging'

# A class for Sea so it can have its own Filter rules.  See Seas for
# how they get created.  The keys are all the keys defined for a
# {Device} plus:
#
# [super]         The original Device.
#
# [real_adapter]  The {Device} entry for the adapter specified in the
#                 +real_adapter+ attribute.
#
# [virt_adapters] The {Device} entries for the adapters specified in
#                 the +virt_adapters+ attribute.
#
# [ctl_chan]      The {Device} entry for the adapter specified in the
#                 +ctl_chan+ attribute.
#
# [pvid_adapter]  The {Device} entry for the adapter (VEA) specified
#                 in the +pvid_adapter+ attribute.
#
class Sea < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
