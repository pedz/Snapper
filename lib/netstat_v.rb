require_relative 'logging'
require_relative "dot_file_parser"
require_relative "write_once_hash"
require_relative "pda"
require_relative "hash_mixins"
require "json"
require "singleton"
require "stringio"

# Parses the output from netstat -v that is found within a snap.
class Netstat_v < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  include HashWriteOnce

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
      table[string] || Entstat_generic
    end

    private

    def table
      @table ||= {}
    end
  end

  # A regular expression that matches the first line of each device
  DEVICE_BOUNDARY = Regexp.new("(FIBRE CHANNEL STATISTICS REPORT: (.*)|ETHERNET STATISTICS \\((.*)\\) :|VASI STATISTICS \\((.*)\\) :)\n")
  private_constant :DEVICE_BOUNDARY

  # For now, we just blow off the VASI gunk.
  VASI = Regexp.new("VASI STATISTICS.*")
  private_constant :VASI

  # Regexp that matches the Device Type: ... line
  DEVICE_TYPE_REGEXP = Regexp.new("^\n?Device Type: +(.*)")
  private_constant :DEVICE_TYPE_REGEXP
  
  # netstat -v is essentially a sequence of calling entstat -d
  # <device> for all of the ethernet devices, all the fiber channel
  # devices, and the VASI devices (whatever those are).
  #
  # This parser splits the entire netstat -v output into pieces by
  # looking for such things as +ETHERNET STATISTICS+ This is done by
  # the DEVICE_BOUNDARY Regexp.
  #
  # Each piece is then taken as a separate entity.  The first line has
  # the device name somewhere within it (e.g. +ETHERNET STATISTICS
  # (ent1) :+ has "ent1" within it.  This provides the logical device
  # name.  In the case of ethernet, the second line is a device type
  # like +Device Type: PCIe2 2-port 10GbE SR Adapter+.
  #
  # The separate decice specific parsers suchs as Entstat_goent
  # register with the Netstat_v parser which device types they can
  # parse.  Thus at parse time, the Netstat_v parser tries to match
  # the second line with one of the registered device types.  If a
  # match is found, a parser of that specific class is created and the
  # parsing is handed off to that instance.  If no match is found, a
  # new Entstat_generic instance is created and the parsing is handed
  # off to it.
  def parse
    parts = @text.split(DEVICE_BOUNDARY)
    fail "No device boundaries found" if parts.length < 3
    unused_empty = parts.shift  # stuff before first match
    while parts.length > 2
      whole_line, device_name, rest = parts.shift(3)
      next if VASI.match(whole_line)
      logger.debug { "DEVICE NAME: #{device_name}" }

      begin
        self[device_name] = find_parser(rest).new(rest, @db).parse
      rescue => e
        new_message = e.message.split("\n").insert(1, "Device name: #{device_name}").join("\n")
        new_e = e.exception(new_message)
        new_e.set_backtrace(e.backtrace)
        raise new_e
      end
    end
    self
  end

  private

  # The parse routine that takes the text in the form of an StringIO
  # parses it using Productions.
  def find_parser(text)
    md = DEVICE_TYPE_REGEXP.match(text)
    fail "'Device Type:' string not found" unless md
    Netstat_v::Parsers.instance.find(md[1])
  end
end
