require_relative "file_parser"
require_relative "item"
require_relative 'logging'
require_relative 'snapper'

# Parse the output of "errpt -a"
class ErrptOutParser < FileParser
  include Logging
  LOG_LEVEL = Logger::INFO    # The log level that ErrptOutParser uses.

  Fields = Regexp.new(/\A(LABEL|IDENTIFIER|Date\/Time|Sequence Number|Machine Id|Node Id|Class|Type|WPAR|Resource Name):[ \t]+([^ \t].*)\Z/)
  DashSeparator = Regexp.new(/^-+\n/)
  def parse
    @io.read.split(DashSeparator).each do |entry|
      next if entry.empty?
      item = @db.create_item("Errpt", entry)
      entry.each_line do |line|
        line.chomp!
        if md = Fields.match(line)
          item[md[1]] = md[2]
        else
          (item['extra'] ||= List.new).push(line)
        end
      end
    end
    self
  end
end

Snapper.add_patterns(%r{/general/errpt.out} => ErrptOutParser)
