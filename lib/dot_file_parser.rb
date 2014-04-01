
# Snap has a lot of files that is a concatenation of a sequence of
# various commands with the output separated by a sequence that looks
# like ...\n ... command\n  ...\n.  This file "parses" those files.
# An example of one of these is the tcpip.snap file.
class DotFileParser

  # Pattern that matches the separations between the commands
  DotSeparator = Regexp.new("\n\\.+\n\\.+ +(.+)\n\\.+\n")
  
  # Parse a "dot file".  io is the file to parse while db is the
  # "database" to add the entries to.
  def self.parse(io, db)
    pieces = io.read.split(DotSeparator)
    not_used = pieces.shift     # date or blanks before 1st command
    while true
      name, text = pieces.shift(2)
      break if name.nil?
      db.add(CommandOutput.new(name, text))
    end
  end
end

# A simple class that has two attributes: a name and the text.  The
# name is usually the command the snap command used to create the
# output but not always.  It is whatever the snap command puts into
# the dot separation.  The text is the text that follows (the output
# of the command)
class CommandOutput
  attr_reader :name, :text

  def initialize(name, text)
    @name = name
    @text = text
  end
end
