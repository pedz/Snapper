require 'date'
require 'time'
require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'
require_relative 'snapper'
require_relative "parse_error"

# Snap has a lot of files that is a concatenation of a sequence of
# various commands with the output separated by a sequence that looks
# like
#     ...
#     ... command
#     ...
# This file "parses" those files.
# An example of one of these is the tcpip.snap file.
#
# Each section is turned into an {Item} via {Db#create_item} using the
# full command as the name.  Then the item's {Item#parse} command is
# called.  By default, this does nothing and the result is an Item
# with the text of the command.
#
# But if command maps to an existing class, then its parse method
# would be called.  Examples of these are {NetstatV}, {NetstatIn}, and
# {LslppLc}.
class DotFileParser < FileParser
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Pattern that matches the separations between the commands.  Note
  # that the command used to produce the file is in a subgroup.
  DotSeparator = Regexp.new("\n\\.+\n\\.+ +(.+)\n\\.+\n\n")
  
  # Parse a "dot file".  io is the file to parse and must respond to
  # read with an array while db is the "database" to add the entries
  # to.  The piece of the file before the first separator is usually
  # thrown away but for general.snap, it is used as the time stamp for
  # the {Db#date_time} which is what {Snap#date_time} forwards to.
  def parse
    # Since DotSeparator has a group within it, this results in an
    # array
    #     [ [ lines0 ], command1, [ lines1 ], command2 [ lines2 ],
    #     ... ]
    # The lines0 piece is thrown away.
    pieces = @io.read.split(DotSeparator)
    maybe_date = pieces.shift     # date or blanks before 1st command
    if @path && maybe_date && (!maybe_date.empty?) && (@path.basename.to_s == "general.snap")
      begin
        @db.date_time = DateTime.parse(maybe_date)
      rescue ArgumentError => e
      end
    end
    lines = 4
    while pieces.length > 1
      name, text = pieces.shift(2)
      # ignore empty command names (yes... it happens :-( )
      next if name.match(/\A *\z/)
      begin
        item = @db.create_item(name, text).parse
      rescue ParseError => e
        e.add_message("file section: #{name.inspect}; starting at line #{lines}")
        raise e
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
