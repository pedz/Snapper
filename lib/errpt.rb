require_relative "item"
require_relative 'logging'

# A class for error report entries.  The fields recognized are there:
#
# * LABEL
# * IDENTIFIER
# * Date/Time
# * Sequence Number
# * Machine Id
# * Node Id
# * Class
# * Type
# * WPAR
# * Resource Name
#
# The other fields are appened to the +extra+ field.
class Errpt < Item
end
