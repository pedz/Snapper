require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'
require_relative 'snapper'
require_relative "parse_error"

# A class that parses the ODM files found in a snap such as CuAt.add,
# etc.  The class might should have been called OdmParser or some
# such.
class Odm < FileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Parses io (via each_line) into ODM objects and adds them to db
  # (via {Db#create_item}).  The stanza type determines the type of
  # object.  For example, a stanza starting with CuAt will do
  # CuAt.new(hash) where hash is the attributes found in the ODM
  # stanza.
  def parse
    logger.debug { "#{self.class} parsing #{@path}" }
    raw_line = ""
    full_line = ""
    item = nil
    each_line do |this_line|
      begin
        next if BLANK.match(this_line) # empty line
        raw_line += this_line
        this_line = fix_literals(this_line)

        # Accumulate continuation lines
        full_line += this_line

        # if line ends with a continuation character
        if CONTINUATION.match(this_line)
          full_line.chomp!        # kill line terminator
          full_line.chop!         # kill the \
          next
        end

        # Looks like a new stanza
        if md = full_line.match(/^(\w+):$/)
          item = @db.create_item(md[1])

        # looks like an attribute
        elsif (md = full_line.match(/^\s+(\w+)\s*=\s*((.|\n)*)$/))
          item[md[1]] = convert(md[2])
        else                      # format seems broken
          raise "Bad format"
        end
        
        # line has been processed
        raw_line = ""
        full_line = ""
      rescue => e
        e.add_message("Odm: line:#{@io.lineno}")
        raise e
      end
    end
    self
  end

  private

  BLANK = /^\s*$/
  CONTINUATION = /\\$/

  # @param line [String] The original line from the file
  # @return [String] replace string literals e.g. "\n" with a newline
  #   and "\\" with a single backslash
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
  # @param a [String] original value from the odm file
  # @return [String, Fixnum] If an extra set of double quotes surround
  #   the string, they are removed and the result is returned.  If the
  #   value is only digits with an optional leading minus sign, the
  #   string is converted to an Integer and returned.
  # @raise [RuntimeError] if neither of the two items happens.
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

Snapper.add_file_parsing_patterns(%r{/general/((Pd|Cu)[^.]*\.)(?!vc\.)add\z} => Odm)
Snapper.add_file_parsing_patterns(%r{/objrepos/((Pd|Cu)[^.]*\.)(?!vc\.)add\z} => Odm)

class RawOdm < Odm
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  def initialize(io, db, path = nil)
    super
    dir=@path.dirname
    cmd = "cd #{dir}; ODMDIR=#{dir} odmget `ls Cu* Pd* | egrep -v '\.(vc|add)$|lock'`"
    @io = IO.popen(cmd)
  end
end

Snapper.add_file_parsing_patterns(%r{/objrepos/PdDv\z} => RawOdm) if /aix/.match(RUBY_PLATFORM)
