#!/usr/bin/env ruby

# Load Snapper class and then load all the files under lib.
require_relative 'lib/snapper'
require_relative 'lib/options'
Pathname.glob(Pathname.new(__FILE__).parent + "lib/**/*.rb") { |f| require_relative f }

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

  # Must have at least one snap path
  if ARGV.empty?
    STDERR.puts options.help
    exit 1
  end
  options.dir_list = ARGV

  Snapper.new(options).run
end
