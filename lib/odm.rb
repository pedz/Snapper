require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'

# A class that parses the ODM files found in a snap such as CuAt.add,
# etc.  The class might should have been called OdmParser or some
# such.
class Odm < FileParser
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level used by the Odm class

  # Parses io (via each_line) into ODM objects and adds them to db
  # (via add).  The stanza type determines the type of object.  For
  # example, a stanza starting with CuAt will do CuAt.new(hash) where
  # hash is the attributes found in the ODM stanza.
  def parse
    raw_line = ""
    full_line = ""
    item = nil
    @io.each_line do |this_line|
      next if this_line.match(/^\s*$/) # empty line
      raw_line += this_line
      this_line = fix_literals(this_line)

      # Accumulate continuation lines
      full_line += this_line

      # if line ends with a continuation character
      if this_line.match(/\\$/)
        full_line.chomp!        # kill line terminator
        full_line.chop!         # kill the \
        next
      end

      # Looks like a new stanza
      if md = full_line.match(/^(\w+):$/)
        item = create_item(md[1], @db, raw_line)

        # looks like an attribute
      elsif (md = full_line.match(/^\s+(\w+)\s*=\s*((.|\n)*)$/))
        item << raw_line
        item[md[1]] = convert(md[2])
      else                      # format seems broken
        raise "Bad format"
      end
      
      # line has been processed
      raw_line = ""
      full_line = ""
    end
    self
  end

  private

  # replace string literals e.g. "\n" with a newline and "\\" with 
  def fix_literals(line)
    line.gsub(/\\./) { |match|
      case match
      when '\n'; "\n"
      when '\\'; "\\"
      end
    }
  end

  # Converts a value (right of the equals sign) read from the odm
  # files what it means.  In particular, a string is quoted with an
  # extra set of double quotes and an integer comes in as a string and
  # is converted to an integer.
  def convert(a)
    if md = a.match(/"((.|\n)*)"/)
      return md[1]
    end
    if a.match(/^-?[0-9]+$/)
      return a.to_i
    end
    raise "Can not convert #{a}"
  end
end
