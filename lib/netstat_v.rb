# Loaded by dot_file_parser so we know that logging is already
# loaded.
require_relative 'logging'
require_relative "dot_file_parser"
require_relative "write_once_hash"
require_relative "pda"
require_relative "hash_mixins"
require "json"
require "singleton"
require "stringio"

# Parses the output from netstat -v that is found within a snap.
# netstat -v is essentially a sequence of calling entstat -d <device>
# for all of the ethernet devices, all the fiber channel devices, and
# the VASI devices (whatever the hell those are).  As a result, the
# subclasses of Netstat_v are Entstat_foo where foo is some type of
# meaningful mnemonic -- e.g. sea or goent or elxent.  The subclasses
# register with Netstat_v via the Parsers nested class of what device
# types they can parse.
class Netstat_v < Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

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
