require_relative "file_parser"
require_relative "item"
require_relative 'logging'

# parses inittab.  While there are other files with the same format,
# its probably easier just to create new parsers for those files (like
# general/passwd.etc) than try to make a generic parser.
class InittabParser < FileParser
  def parse
    each_line do |line|
      # Comments are lines that start with a colon
      next if /\A:/.match(line)
      fields = line.split(':')
      # name:level:style:command
      item = @db.create_item("Inittab")
      item[:name]    = fields[0]
      item[:level]   = fields[1]
      item[:style]   = fields[2]
      item[:command] = fields[3]
    end
  end
end

Snapper.add_file_parsing_patterns(%r{/general/inittab} => InittabParser)
