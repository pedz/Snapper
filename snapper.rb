#!/usr/bin/env ruby

require_relative 'lib/snap_parser'
require_relative 'lib/odm'
require_relative 'lib/db'
require_relative 'lib/dot_file_parser'

unless ARGV.length == 1
  $stderr.puts "Usage: snapper <dir>"
  exit 1
end

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

SeaPdDvLn = "adapter/pseudo/sea"
db = Db.new

SnapParser.parse(ARGV[0], nil, db, Patterns)

l = db.table('CuDv').find_all { |cudv|
  cudv.PdDvLn == SeaPdDvLn
}.each { |sea|
  puts "Name: #{sea.name}"
  sea.attributes(db).each_pair { |k, v| puts "    #{k}: #{v}"}
}

# puts db.table('Netstat_v')[0].text
