#!/usr/bin/env ruby

require_relative 'lib/logging'
require_relative 'lib/db'
require_relative 'lib/dot_file_parser'
require_relative 'lib/odm'
require_relative 'lib/page'
require_relative 'lib/snap_parser'

# A class that represents the snapper program
class Snapper
  extend Page
  include Logging
  # The log level for the Snapper class
  LOG_LEVEL = Logger::INFO
  
  # A hash of file patterns and the parser to use for that file.
  Patterns = {
    %r{/general/([^.]*\.)(?!vc\.)add\z} => Odm, # ODM files in general but not the vc files
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
  def self.run(dir_list)
    db_list = dir_list.map do |directory|
      db = Db.new
      SnapParser.parse(directory, nil, db, Patterns)
      db
    end
    create_page(db_list)
  end
end

if __FILE__ == $0
  if ARGV.length == 0
    $stderr.puts "Usage: snapper <dir> ..."
    exit 1
  end
  Snapper.run(ARGV)
end
