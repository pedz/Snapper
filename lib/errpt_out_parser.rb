require_relative "file_parser"
require_relative "item"
require_relative 'logging'

# Parse the output of "errpt -a"
class ErrptOutParser < FileParser
  include Logging
  LOG_LEVEL = Logger::INFO    # The log level that ErrptOutParser uses.

  Fields = Regexp.new(/\A(LABEL|IDENTIFIER|Date\/Time|Sequence Number|Machine Id|Node Id|Class|Type|WPAR|Resource Name):[ \t]+([^ \t].*)\Z/)
  DashSeparator = Regexp.new(/^-+\n/)
  def parse
    @io.read.split(DashSeparator).each do |entry|
      next if entry.empty?
      item = create_item("Errpt", @db, entry)
      entry.each_line do |line|
        line.chomp!
        if md = Fields.match(line)
          item[md[1]] = md[2]
        else
          (item['extra'] ||= []).push(line)
        end
      end
    end
    self
  end
end
