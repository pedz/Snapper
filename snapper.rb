#!/usr/bin/env ruby

# "Quick Bug" -- used for quick printf style debugging.  The output
# file can be changed via the -q command.  The default is $stderr
$qb = $stderr
# Quick Bug does a puts to the quick bug output file passing it the
# args that it was passed.
# @param args [Array<Object>]
def qb(*args)
  $qb.puts(*args)
end

$snapper_version = "%%% VERSION %%%"
$snapper_release = "%%% RELEASE %%%"

# Load Snapper class and then call it
require_relative 'lib/snapper'
Snapper.new.run
