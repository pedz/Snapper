require_relative "dot_file_parser"

# Parses the no -a output found in tcpip/tcpip.snap.  Converts values
# that begin with a digit to Fixnum (integers).
class No_a < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Matches a line with:
  #  1: whitespace (spaces and tabs)
  #  2: a word that does not have any whitespace (key)
  #  3: whitespace (usually exactly 1 space)
  #  4: =
  #  5: whitespace (again, usually exactly 1 space)
  #  6: non-whitespace until EOL (value)
  NO_A_REGEXP = /\A\s*(?<key>\S+)\s*=\s*(?<value>\S.*)\Z/
  def parse
    @text.each_line do |line|
      next unless md = NO_A_REGEXP.match(line)
      key = md[:key]
      value = md[:value]
      value = value.to_i if ("0" .. "9").include?(value[0])
      self[key] = value
    end
    self
  end
end
