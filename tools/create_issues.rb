#!/usr/bin/env ruby

require 'pathname'
require 'net/ssh'
require 'set'

if true
  PSQL="/usr/bin/psql"
  HOST="condor3.austin.ibm.com"
  DB="condor3_production"
elsif false
  PSQL="/gsa/ausgsa/projects/r/ruby/pgsql/bin/psql"
  HOST="condor.austin.ibm.com"
  DB="condor3_production"
else
  PSQL="/usr/local/pgsql/bin/psql"
  HOST="p51.austin.ibm.com"
  DB="condor_development"
end
$defects = Set.new

base = Pathname(__FILE__).dirname.dirname
issues_rb = base + "issues.rb"
issues_txt = base + "tools/issues.txt"

new_code = issues_rb.open("w", 0644)
new_code.puts <<HEADER
# This file is automatically produced by #{__FILE__}
# array of issues.  each issue is an array:
# [ injecting defect, resolving defect, text ]
class BrokenFilesets

@issues = [
HEADER
previous_line = nil
issues_txt.open do |file|
  file.each_line do |line|
    next if /^#/.match(line)
    fields = line.chomp.split('|')
    $defects.add(fields[0].strip) unless fields[0].strip == "true"
    $defects.add(fields[1].strip)
    new_code.puts "#{previous_line}," unless previous_line.nil?
    proc = fields[3 .. -1].join('|')
    previous_line = "  [ #{fields[0].strip.inspect}, #{fields[1].strip.inspect}, #{fields[2].strip.inspect}, Proc.new #{proc} ]"
  end
end
new_code.puts previous_line unless previous_line.nil?
new_code.puts "]"
new_code.puts
new_code.puts "# Hash that maps a defect to a list of APARs"
new_code.puts "@defect2apars = {"
previous_line = nil
puts "about to log into #{HOST}"
Net::SSH.start(HOST, 'condor') do |ssh|
  puts "Logged into #{HOST} and doing #{$defects.length} queries"
  $defects.each do |defect|
    # puts "execing: #{PSQL} -c \"copy ( select distinct apar from ptfapardefs where defect = '#{defect}' order by apar ) to stdout;\" #{DB}"
    output = ssh.exec!("#{PSQL} -c \"copy ( select distinct apar from ptfapardefs where defect = '#{defect}' order by apar ) to stdout;\" #{DB}")
    raise Exception.new("psql failed") unless output.exitstatus == 0
    output = output.split("\n")
    output.delete("NEEDS_APAR")
    new_code.puts "#{previous_line}," unless previous_line.nil?
    if output.empty?
      previous_line = "  #{defect.inspect} => [ ]"
    else
      previous_line = "  #{defect.inspect} => [ \"#{output.join('", "')}\" ]"
    end
  end
end
new_code.puts previous_line unless previous_line.nil?
new_code.puts <<TRAILER
}

end
TRAILER
new_code.close
