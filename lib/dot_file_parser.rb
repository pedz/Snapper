require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'

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
  LOG_LEVEL = Logger::INFO    # The log level that DotFileParser uses.

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
    not_used = pieces.shift     # date or blanks before 1st command
    lines = 5
    while pieces.length > 1
      name, text = pieces.shift(2)
      next if name.match(/\A *\z/) # yes... it happens :-(
      begin
        @db.create_item(name, text).parse
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
