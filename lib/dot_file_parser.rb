require 'date'
require 'time'
require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'
require_relative 'snapper'

# Snap has a lot of files that is a concatenation of a sequence of
# various commands with the output separated by a sequence that looks
# like
#     ...
#     ... command
#     ...
# This file "parses" those files.
# An example of one of these is the tcpip.snap file.
class DotFileParser < FileParser
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Pattern that matches the separations between the commands.  Note
  # that the command used to produce the file is in a subgroup.
  DotSeparator = Regexp.new("\n\\.+\n\\.+ +(.+)\n\\.+\n\n")
  
  # Parse a "dot file".  io is the file to parse and must respond to
  # read with an array while db is the "database" to add the entries
  # to.  The piece of the file before the first separator is thrown
  # away.
  def parse
    # Since DotSeparator has a group within it, this results in an
    # array
    #     [ [ lines0 ], command1, [ lines1 ], command2 [ lines2 ],
    #     ... ]
    # The lines0 piece is thrown away.
    pieces = @io.read.split(DotSeparator)
    maybe_date = pieces.shift     # date or blanks before 1st command
    unless @path && @path.basename == "general.snap" && maybe_date.empty?
      begin
        @db.date_time = DateTime.parse(maybe_date)
      rescue ArgumentError => e
      end
    end
    lines = 5
    while pieces.length > 1
      name, text = pieces.shift(2)
      next if name.match(/\A *\z/) # yes... it happens :-(
      begin
        item = @db.create_item(name, text).parse
        # item['Date/Time'] = date_time
      rescue => e
        new_message = e.message.split("\n").insert(1, "dot file parser: lineno:#{lines}").join("\n")
        new_e = e.exception(new_message)
        new_e.set_backtrace(e.backtrace)
        raise new_e
      end
      lines += (text.lines.count + 5)
    end
    self
  end
end

Snapper.add_file_parsing_patterns(
  %r{/XS25/XS25.snap} => DotFileParser,
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
)
