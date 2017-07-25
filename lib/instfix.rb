require_relative 'device'
require_relative 'logging'

# A class for instfix records found in perfpmr data.
#
# [fileset]   The fileset that is affected
#
# [required]  The required VRMF
#
# [installed] The installed VRMF
#
# [status]    The status of the fix
#
# [abstract]  The abstract for the APAR
#
class Instfix < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
end
