#!/usr/bin/env ruby

require 'optparse'
# Load Snapper class and then load all the files under lib.
require_relative 'lib/snapper'
Dir.glob('lib/**/*.rb') { |f| require_relative f }

if __FILE__ == $0
  options = OpenStruct.new
  options.print_keys = false
  options.level = 1
  options.dump = false

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__.sub(/.*\//, "")} [options] <path to snap1> [ <path to snap2> ... ]"

    opts.on("-D",
            "--dump",
            "For each snap, creates a .ruby.dump.gz file",
            "at the base directory of the snap with the",
            "parse tree of the snap.  This file will be",
            "automatically loaded instead of re-parsing",
            "the files within the snap.") do |d|
      options.dump = d
    end

    opts.on("-k",
            "--print_keys",
            "Print the top level keys") do |k|
      options.print_keys = k
    end

    opts.on("-l N",
            "--level N",
            Integer,
            "Output verbosity level from -1 to 11",
            "default is 1") do |l|
      if l < -1 || l > 11
        STDERR.puts "level out of range"
        STDERR.puts opt_parser.help
        exit 1
      end
      options.level = l
    end

    opts.on_tail("-h",
                 "-?",
                 "--help",
                 "Show this message") do
      puts opts
      exit
    end
  end

  begin
    opt_parser.parse!(ARGV)
  rescue => e
    STDERR.puts e.message
    exit 1
  end

  # Must have at least one snap path
  if ARGV.empty?
    STDERR.puts opt_parser.help
    exit 1
  end
  options.dir_list = ARGV

  Snapper.new(options).run
end
