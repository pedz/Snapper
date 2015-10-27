#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

Dir.glob('lib/**/*.rb') { |f| require_relative f }

# A class that represents the snapper program
class Snapper
  # Add this back in when create_page is being used again
  # extend Page

  include Logging
  LOG_LEVEL = Logger::INFO      # The log level for the Snapper class
  
  # A hash of file patterns and the parser to use for that file.
  Patterns = {
    %r{/general/([^.]*\.)(?!vc\.)add\z} => Odm, # ODM files in general but not the vc files
    %r{/general/errpt.out} => ErrptOutParser,
    %r{/async/async.snap} => DotFileParser,
    %r{/dump/dump.snap} => DotFileParser,
    %r{/filesys/filesys.snap} => DotFileParser,
    %r{/general/general.snap} => DotFileParser,
    %r{/kernel/kernel.snap} => DotFileParser,
    %r{/lang/lang.snap} => DotFileParser,
    %r{/lvm/altinst_rootvg.snap} => DotFileParser,
    %r{/lvm/gsclvmd.snap} => DotFileParser,
    %r{/lvm/lvm.snap} => DotFileParser,
    %r{/lvm/lvmcfg.log} => DotFileParser,
    %r{/lvm/lvmgs.log} => DotFileParser,
    %r{/lvm/lvmt.log} => DotFileParser,
    %r{/lvm/rootvg.snap} => DotFileParser,
    %r{/nfs/nfs.snap} => DotFileParser,
    %r{/pcixscsi/pcixscsi.snap} => DotFileParser,
    %r{/printer/printer.snap} => DotFileParser,
    %r{/sissas/sissas.snap} => DotFileParser,
    %r{/sna/sna.snap} => DotFileParser,
    %r{/ssa/ssa.snap} => DotFileParser,
    %r{/tcpip/tcpip.snap} => DotFileParser,
    %r{/wpars/wpars.snap} => DotFileParser,
    %r{/XS25/XS25.snap} => DotFileParser,
  }
  
  # Called with dir_list set to an array of directories.  Each
  # directory should point to the top of a snap.
  def self.run(options)
    db_list = options.dir_list.map do |directory|
      db = Db.new
      SnapParser.new(directory, nil, db, Patterns).parse
      db
    end

    if options.print_keys
      puts db_list[0].keys.sort
      return
    end

    # We use to call create_page here to create an HTML page with
    # pretty pictures.  I'm going to leave that call here commented
    # out for now.
    # create_page(db_list)
    # Devices.create(db_list)
    # Print.out(db_list)
  end
end

if __FILE__ == $0
  options = OpenStruct.new
  options.print_keys = false
  options.level = 1

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__.sub(/.*\//, "")} [options] <path to snap1> [ <path to snap2> ... ]"

    opts.on("-k", "--print_keys", "Print the top level keys") do |k|
      options.print_keys = k
    end

    opts.on("-l N", "--level N", Integer, "Output verbosity level from 0 to 11", "default is 1") do |l|
      if l < 0 || l > 11
        STDERR.puts "level out of range"
        STDERR.puts opt_parser.help
        exit 1
      end
      options.level = l
    end

    opts.on_tail("-h", "--help", "Show this message") do
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

  # Must have at least one snap directory
  if ARGV.empty?
    STDERR.puts opt_parser.help
    exit 1
  end
  options.dir_list = ARGV

  Snapper.run(options)
end
