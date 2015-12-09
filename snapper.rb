#!/usr/bin/env ruby

# Load Snapper class and then load all the files under lib.
require_relative 'lib/snapper'
require_relative 'lib/options'

$progname = __FILE__.sub(/.*\//, "")
$qb = $stderr
# "Quick Bug" -- used for quick printf style debugging
def qb(*args)
  $qb.puts(*args)
end

if __FILE__ == $0
  begin
    options = Options.new($progname).parse!(ARGV)
  rescue => e
    STDERR.puts e.message
    exit 1
  end

  Pathname.glob(Pathname.new(__FILE__).parent.realpath + "lib/**/*.rb") { |f| require_relative f }

  # Must have at least one snap path
  if options.dir_list.empty?
    STDERR.puts options.help
    exit 1
  end

  Snapper.new(options).run
end
