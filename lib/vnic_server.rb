require_relative 'device'
require_relative 'logging'

# A class for Vnicserver so it can have its own Filter rules.  See
# Vnicservers for how they get created.  The keys are all the keys
# defined for a {Device} plus:
#
# [super]         The original Device.
#
class VnicServer < Device
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def <=>(b)
    self.unit <=> b.unit
  end

  def unit
    @unit ||= self.name.sub(/\A[^0-9]+/, '').to_i
  end
end
