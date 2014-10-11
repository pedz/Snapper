# Loaded by dot_file_parser so we know that logging is already
# loaded.
require "dot_file_parser"
require "singleton"
require "json"

# Parses the output from netstat -v that is found within a snap.
# netstat -v is essentially a sequence of calling entstat -d <device>
# for all of the ethernet devices, all the fiber channel devices, and
# the VASI devices (whatever the hell those are).
class Netstat_v < DotFileParser::Base
  include Logging
  # The log level the Netstat_v uses.
  LOG_LEVEL = Logger::INFO

  # Each type of adapter has its own parser for the output the its
  # entstat.foo produces.  These parsers declare their existance by
  # adding themselves to Netstat_v::Parsers.add.
  class Parsers
    include Singleton
    
    # Each parser adds its class and the device strings that it
    # understands by calling add.
    def add(klass, string)
      table[string] = klass
    end

    # The netstat_v front end finds the adapter specific parser by
    # passing the string after "Device type:" to this routine
    def find(string)
      table[string]
    end

    private

    def table
      @table ||= {}
    end
  end

  # A regular expression that matches the first line of each device
  DEVICE_BOUNDARY = Regexp.new("(FIBRE CHANNEL STATISTICS REPORT: (.*)|ETHERNET STATISTICS \\((.*)\\) :|VASI STATISTICS \\((.*)\\) :)\n")
  VASI = Regexp.new("VASI STATISTICS.*")

  private_constant :DEVICE_BOUNDARY

  # text is the full output of netstat -v.  The text is parsed
  # breaking it first into the pieces for each device.  Each device is
  # a specific type of adapter.  The pieces are thus passed to the
  # adapter specific parser.
  def initialize(text)
    @text = text
    @result = {}
    parts = text.split(DEVICE_BOUNDARY)
    fail "No device boundaries found" if parts.length < 3
    unused_empty = parts.shift  # stuff before match
    while true
      whole_line, device_name, rest = parts.shift(3)
      break if whole_line.nil?
      next if VASI.match(whole_line)
      logger.debug { "DEVICE NAME: #{device_name}" }
      begin
        @result[device_name] = parse_lines(rest)
      rescue => e
        new_e = e.exception("Device name: #{device_name}\n#{e.message}")
        new_e.set_backtrace(e.backtrace)
        raise new_e
      end
    end
  end

  # Regexp that matches the Device Type: ... line
  DEVICE_TYPE_REGEXP = Regexp.new("^\n?Device Type: +(.*)")
  private_constant :DEVICE_TYPE_REGEXP
  
  private

  # The parse routine that takes the text in the form of an StringIO
  # parses it using Productions.
  def parse_lines(text)
    md = DEVICE_TYPE_REGEXP.match(text)
    fail "'Device Type:' string not found" unless md
    parser = Netstat_v::Parsers.instance.find(md[1])
    fail "No device specific parser for '#{md[1]}'" unless parser
    return parser.new(text).result
  end
end
