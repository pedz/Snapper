#!/usr/bin/env ruby

require 'pathname'
require 'net/ssh'
require 'set'

PSQL="/gsa/ausgsa/projects/r/ruby/pgsql/bin/psql"
$defects = Set.new

base = Pathname(__FILE__).dirname.dirname
issues_rb = base + "issues.rb"
issues_txt = base + "tools/issues.txt"

new_code = issues_rb.open("w", 0644)
new_code.puts "# This file is automatically produced by #{__FILE__}"
new_code.puts "# array of issues.  each issue is an array:"
new_code.puts "# [ injecting defect, resolving defect, text ]"
new_code.puts "$issues = ["
previous_line = nil
issues_txt.open do |file|
  file.each_line do |line|
    next if /^#/.match(line)
    fields = line.split('|')
    $defects.add(fields[0].strip)
    $defects.add(fields[1].strip)
    new_code.puts "#{previous_line}," unless previous_line.nil?
    previous_line = "  [ #{fields[0].strip.inspect}, #{fields[1].strip.inspect}, #{fields[2].strip.inspect} ]"
  end
end
new_code.puts previous_line unless previous_line.nil?
new_code.puts "]"
new_code.puts
new_code.puts "# Hash that maps a defect to a list of APARs"
new_code.puts "$defect2apars = {"
previous_line = nil
Net::SSH.start('condor.austin.ibm.com', 'condor') do |ssh|
  $defects.each do |defect|
    output = ssh.exec!("#{PSQL} -c \"copy ( select distinct apar from ptfapardefs where defect = '#{defect}' order by apar ) to stdout;\" condor3_production")
    raise Exception.new("psql failed") unless output.exitstatus == 0
    output = output.split("\n")
    output.delete("NEEDS_APAR")
    new_code.puts "#{previous_line}," unless previous_line.nil?
    previous_line = "  #{defect.inspect} => [ \"#{output.join('", "')}\" ]"
  end
end
new_code.puts previous_line unless previous_line.nil?
new_code.puts "}"
new_code.close
