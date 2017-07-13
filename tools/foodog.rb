#!/usr/bin/env ruby

require 'net/ssh'
require 'set'

PSQL="/gsa/ausgsa/projects/r/ruby/pgsql/bin/psql"
$defects = Set.new

blah = File.open("new_code.rb", "w", 0644)
blah.puts "# This file is automatically produced by #{__FILE__}"
blah.puts "# array of issues.  each issue is an array:"
blah.puts "# [ injecting defect, resolving defect, text ]"
blah.puts "$issues = ["
previous_line = nil
File.open(__FILE__ + "/../issues.txt") do |file|
  file.each_line do |line|
    next if /^#/.match(line)
    fields = line.split('|')
    $defects.add(fields[0].strip)
    $defects.add(fields[1].strip)
    blah.puts "#{previous_line}," unless previous_line.nil?
    previous_line = "  [ #{fields[0].strip.inspect}, #{fields[1].strip.inspect}, #{fields[2].strip.inspect} ]"
  end
end
blah.puts previous_line unless previous_line.nil?
blah.puts "]"
blah.puts
blah.puts "# Hash that maps a defect to a list of APARs"
blah.puts "$defect2apars = {"
previous_line = nil
Net::SSH.start('condor.austin.ibm.com', 'condor') do |ssh|
  $defects.each do |defect|
    output = ssh.exec!("#{PSQL} -c \"copy ( select distinct apar from ptfapardefs where defect = '#{defect}' order by apar ) to stdout;\" condor3_production")
    raise Exception.new("psql failed") unless output.exitstatus == 0
    output = output.split("\n")
    output.delete("NEEDS_APAR")
    blah.puts "#{previous_line}," unless previous_line.nil?
    previous_line = "  #{defect.inspect} => [ \"#{output.join('", "')}\" ]"
  end
end
blah.puts previous_line unless previous_line.nil?
blah.puts "}"
blah.close
