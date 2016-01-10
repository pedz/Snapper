require_relative 'file_parser'

# If you want to just suck up a file text.
class TextFileParser < FileParser
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  def parse
    @db.create_item(@path.basename.to_s, @io.read)
  end
end

Snapper.add_file_parsing_patterns(
  %r{/svCollect/VIOS.level} => TextFileParser
)
