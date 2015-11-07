#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'zlib'

Dir.glob('lib/**/*.rb') { |f| require_relative f }

# A class that represents the snapper program
class Snapper
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level for the Snapper class
  
  # A hash of file patterns and the parser to use for that file.
  Patterns = {
    %r{/XS25/XS25.snap} => DotFileParser,
    %r{/async/async.snap} => DotFileParser,
    %r{/dump/dump.snap} => DotFileParser,
    %r{/filesys/filesys.snap} => DotFileParser,
    %r{/general/([^.]*\.)(?!vc\.)add\z} => Odm, # ODM files in general but not the vc files
    %r{/general/errpt.out} => ErrptOutParser,
    %r{/general/general.snap} => DotFileParser,
    %r{/general/lparstat.out} => ColonFileParser,
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
  }
  
  def initialize(options)
    @options = options
  end

  # Called with dir_list set to an array of directories.  Each
  # directory should point to the top of a snap.
  def run
    snap_list = @options.dir_list.map do |path|
      path = Pathname(path)
      result = nil
      if path.directory?
        if dump_file(path).file?
          Zlib::GzipReader.open(dump_file(path)) do |gz|
            result = restore(gz.read)
          end
        else
          db = Db.new
          SnapParser.new(path, nil, db, Patterns).parse
          result = OpenStruct.new({ dir: path, db: db, alerts: [] })
          if @options.dump
            Zlib::GzipWriter.open(dump_file(path), 9) do |gz|
              Marshal.dump([ Item.children, result ], gz)
            end
          end
        end
        result
      elsif path.file?
        restore(path.read)
      end
    end
    list = OpenStruct.new({ snap_list: snap_list, alerts: [] })

    # This section will be a sequence of calls that will rummage
    # around in the snap list either creating conveninece items or
    # adding alerts in various places.  In theory, it should be
    # possible to make this an extensible list.
    Devices.create(list)

    # From here down will be output routines
    if @options.print_keys
      puts snap_list[0][:db].keys.sort
      return
    end

    # put out the top level alerts first -- perhaps with splats.
    list.alerts.each do |alert|
      # print out alerts
    end

    # Then for each snap
    list.snap_list.each do |snap|
      # print the hostname block
      print_hostname(snap)
      
      # print the alerts for this host
      snap.alerts.each do |alert|
        # print out alerts
      end
      
      print_interfaces(snap)
      # print_seas(snap)
    end
  end

  private
  
  def dump_file(path)
    @dump_file ||= (path + ".ruby.dump.gz")
  end

  ##
  # The marshaled entity is two element array.  The first element is
  # an array of class names that subclassed Item.  The second element
  # is the OpenStruct which we called result.  The proc finds the
  # first array during the deserializing and then scans that array of
  # strings creating classes.  This occurs before any of the result is
  # scanned.  Thus the classes created during the parsing are
  # recreated before the result is scanned.
  def restore(io)
    done = false
    p = Proc.new  { |obj|
      if (done == false) && (obj.class == Array)
        obj.each do |classname|
          ::Object.const_set(classname, Class.new(Item)) unless ::Object.const_defined?(classname)
        end
        done = true
      end
      obj
    }
    class_array, result = Marshal.restore(io, p)
    result
  end

  def print_hostname(snap)
    db = snap.db
    if @options.level > 2
      puts "#" * 80
      puts "##{db.lparstat_out.node_name.center(78)}#"
      puts "#" * 80
    else
      puts "Host: #{db.lparstat_out.node_name}"
    end
  end

  def print_interfaces(snap)
    new = snap.db.devices.select do |key, value|
      value.netstat_in
    end
    puts new.keys
  end
end

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

  # Must have at least one snap path
  if ARGV.empty?
    STDERR.puts opt_parser.help
    exit 1
  end
  options.dir_list = ARGV

  Snapper.new(options).run
end
