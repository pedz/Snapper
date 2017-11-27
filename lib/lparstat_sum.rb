require 'date'
require 'time'
require_relative 'logging'
require_relative 'file_parser'
require_relative 'colon_file_parser'
require_relative 'item'
require_relative 'snapper'

class LparstatSumParser < ColonFileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # The lparstat.sum file in a perfpmr has a header in front of the
  # lparstat output that is removed first.
  def parse
    line = @io.gets until md = /\ATime before run:\s+(?<time>.*)\Z/.match(line)
    return unless md
    @db.date_time ||= DateTime.parse(md[:time])
    super
    @db["lparstat_out"] = @db["lparstat_sum"]
  end
end

Snapper.add_file_parsing_patterns(%r{lparstat.sum} => LparstatSumParser)
