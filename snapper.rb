#!/usr/bin/env ruby

# "Quick Bug" -- used for quick printf style debugging
$qb = $stderr
def qb(*args)
  $qb.puts(*args)
end

# Load Snapper class and then call it
require_relative 'lib/snapper'
Snapper.new.run
