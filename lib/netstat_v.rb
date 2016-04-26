require_relative 'logging'
require_relative "dot_file_parser"
require_relative "write_once_hash"
require_relative "pda"
require_relative "hash_mixins"
require_relative "parse_error"
require "json"
require "singleton"
require "stringio"

# Parses the output from <tt>netstat -v</tt> that is found within
# +tcpip.snap+.
class NetstatV < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  include HashWriteOnce

  # Each type of adapter has its own parser for the output the its
  # entstat.foo produces.  These parsers declare their existance by
  # adding themselves via {NetstatV::Parsers.add}.
  class Parsers
    include Singleton
    
    # Each parser registers its class and the device strings that it
    # understands by calling this method.
    # @param klass [Class] The class to add
    # @param string [String] The string after <tt>Device Type:</tt> in
    #   the entstat output that this class can parse.
    def add(klass, string)
      table[string] = klass
    end

    # The +netstat_v+ front end finds the adapter specific parser by
    # passing the string after "Device type:" to this routine
    # @param string [String] the string after <tt>Device type:</tt>.
    # @return [Class] The class that registered for this specific
    #   string or {EntstatGeneric} if no registration is found.
    def find(string)
      table[string] || EntstatGeneric
    end

    private

    # @return [Hash] the hash table of String to Class
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
  
  # <tt>netstat -v</tt> is essentially a sequence of calling
  # <tt>entstat -d <device></tt> for all of the ethernet devices, all
  # the fiber channel devices, and the VASI devices (whatever those
  # are).
  #
  # This parser splits the entire netstat -v output into pieces by
  # looking for such things as <tt>ETHERNET STATISTICS</tt> This is
  # done by the DEVICE_BOUNDARY Regexp.
  #
  # Each piece is then taken as a separate entity.  The first line has
  # the device name somewhere within it (e.g. <tt>ETHERNET STATISTICS
  # (ent1) :</tt> has "ent1" within it.  This provides the logical
  # device name.  In the case of ethernet, the second line is a device
  # type like <tt>Device Type: PCIe2 2-port 10GbE SR Adapter</tt>.
  #
  # The separate decice specific parsers suchs as {EntstatGoent}
  # register with {NetstatV::Parsers#add} which device types they can
  # parse.  Thus at parse time, the {NetstatV} parser tries to match
  # the second line with one of the registered device types.  If a
  # match is found, a parser of that specific class is created and the
  # parsing is handed off to that instance.  If no match is found, a
  # new EntstatGeneric instance is created and the parsing is handed
  # off to it.
  # @raise [RuntimeError] if no device boundary is found.
  def parse
    parts = @text.split(DEVICE_BOUNDARY)
    fail "No device boundaries found" if parts.length < 3
    unused_empty = parts.shift  # stuff before first match
    lines = 2
    while parts.length > 2
      whole_line, device_name, rest = parts.shift(3)
      lines += 1
      if VASI.match(whole_line)
        lines += rest.lines.count
        next
      end
      logger.debug { "DEVICE NAME: #{device_name}" }

      begin
        temp = find_parser(rest).new(rest, @db).parse
        self[device_name] = temp unless self[device_name]
      rescue ParseError => e
        e.add_message("Device name: #{device_name}; relative line within section: #{lines}")
        raise e
      end
      lines += rest.lines.count
    end
    self
  end

  private

  # Finds the class that will parse the text passed in.
  # @param text [String] The rest of the <tt>entstat -d</tt> output.
  # @return [Class] The class that has registered to parse the text
  #   based upon the text after <tt>Device Type:<\tt>.
  # @raise [RuntimeError] if the device type is not found.
  def find_parser(text)
    md = DEVICE_TYPE_REGEXP.match(text)
    fail "'Device Type:' string not found" unless md
    NetstatV::Parsers.instance.find(md[1])
  end
end
