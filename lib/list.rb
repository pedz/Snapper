require_relative 'logging'

# This is not really used yet.  To be useful, it needs to use the same
# missing_method tech that Item uses and then the print in Enumerable
# could be moved into here.  But, so far, the current set up hasn't
# bit me yet so I'm going to leave it alone for now.
class List < Array
end
