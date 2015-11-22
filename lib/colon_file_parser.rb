require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'
require_relative 'snapper'

# Parses lparstat.out but it may be general enough to parse other
# files as well.  In brief, each line has a field name on the left, a
# colon, and a value on the right.  white space before and after the
# field name and value is stripped but white space within the field or
# value is kept.  If all the characters are digits, it is converted to
# an integer
class ColonFileParser < FileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
  
  # The Regexp used to scan each line
  LINE_REGEXP = /\A\s*(?<field>\S.*):\s*(?<value>\S.*)\Z/

  # A Regexp that matches if the string has only digits and at least
  # one digit.
  ALL_DIGITS = /\A[0-9]+\Z/

  # parses the file line by line matching it against LINE_REGEXP.  If
  # it matches a new entry is created with the field and value.  Value
  # is converted to an integer if it only contains digits.
  def parse
    name = @io.path.sub(/\A.*\//, '')
    text = @io.read
    item = @db.create_item(name, text)
    text.each_line do |line|
      fail "Line did not parse" unless (md = LINE_REGEXP.match(line))
      field = md[:field].strip
      value = md[:value].strip
      value = value.to_i if ALL_DIGITS.match(value)
      item[field] = value
    end
  end
end

Snapper.add_file_parsing_patterns(%r{/general/lparstat.out} => ColonFileParser)
