require_relative "file_parser"
require_relative "item"
require_relative 'logging'
require_relative 'snapper'

# Parse the output of "errpt -a"
class ErrptOutParser < FileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # A regular expresion for the fields in an error log entry that are
  # parsed.  Other fields are just added to the _extra_ field.  The
  # list of known fields are:
  #
  # * LABEL
  # * IDENTIFIER
  # * Date/Time
  # * Sequence Number
  # * Machine Id
  # * Node Id
  # * Class
  # * Type
  # * WPAR
  # * Resource Name
  Fields = Regexp.new(/\A(LABEL|IDENTIFIER|Date\/Time|Sequence Number|Machine Id|Node Id|Class|Type|WPAR|Resource Name):[ \t]+([^ \t].*)\Z/)

  # A regular expresion that matches the dashed line between error log
  # entries.
  DashSeparator = Regexp.new(/^-+\n/)

  # Parses the errpt.out file using DashSeparator to break the entries
  # apart and then Fields to identify known fields within the error
  # log entry and put them in to their own entry.
  def parse
    @io.read.split(DashSeparator).each do |entry|
      next if entry.empty?
      item = @db.create_item("Errpt", entry)
      entry.each_line do |line|
        line.chomp!
        if md = Fields.match(line)
          logger.debug { "adding #{md[1]}"}
          item[md[1]] = md[2]
        else
          (item['extra'] ||= List.new).push(line)
        end
      end
    end
    # We always want errpt to be an array so we add two items (which
    # forces it to be an array even if it was empty originally) and
    # then pop them off.
    unless @db["Errpt"].is_a? Array
      @db.create_item("Errpt", "")
      @db.create_item("Errpt", "")
      @db["Errpt"].pop(2)
    end
    self
  end
  # @param  remove me
end

Snapper.add_file_parsing_patterns(%r{/general/errpt.out} => ErrptOutParser)
