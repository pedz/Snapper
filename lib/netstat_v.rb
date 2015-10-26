# Loaded by dot_file_parser so we know that logging is already
# loaded.
require_relative "dot_file_parser"
require_relative "write_once_hash"
require_relative "pda"
require "json"
require "singleton"
require "stringio"

# Parses the output from netstat -v that is found within a snap.
# netstat -v is essentially a sequence of calling entstat -d <device>
# for all of the ethernet devices, all the fiber channel devices, and
# the VASI devices (whatever the hell those are).
class Netstat_v < Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

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
      table[string] || Netstat_v_generic
    end

    private

    def table
      @table ||= {}
    end
  end

  class Base < Item
    include Logging
    LOG_LEVEL = Logger::INFO    # The log level that Netstat_v_elxent uses:

    # These productions should be in every netstat_v_* parser.  There
    # are four productions:
    #   1: | *field: int_value
    #   2: | *field: optional_value
    #   3: |Real Adapter: entNN (as well as Virtual and Control)
    #   4: |burst and empty lines
    BASE_PRODUCTIONS =
      [
       # Sample Match:   |Adapter Reset Count: 0
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # For lines with exactly one colon and the value is an integer.
       # Leading white space is allowed.  Text before colon is
       # md[:field].  Text after colon is md[:value].  Leading and
       # trailing white space from both are stripped.  Value can not
       # be empty and is converted to an integer.
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>-?\\d+)\\s*$", [:normal]) do |md, pda|
         field = md[:field].strip
         value = md[:value].to_i
         pda.target[field] = value
       end,
       
       # Sample Match:   |  Device Type: FC Adapter (adapter/pciex/df1000f114108a0)
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # For lines with exactly one colon.  Leading white space is
       # allowed.  Text before colon is md[:field].  Text after colon
       # is md[:value].  Leading and trailing white space from both
       # are stripped.  value can be empty.
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>[^: ]*[^:]*)$", [:normal]) do |md, pda|
         field = md[:field].strip
         value = md[:value].strip
         pda.target[field] = value
       end,
       
       # Sample Match:   |Control Adapter: ent14
       # States Matched: :all
       # New State:      :no_change
       # State Pushed:   none
       # Lines which are always ignored.
       PDA::Production.new("^(Control|Backup|Real|Virtual) Adapter: ent\\d+\\s*$") do |md, pda|
       end,
       
       # Sample Match:   |empty lines and lines with only -'s and ='s
       # States Matched: :all
       # New State:      :no_change
       # State Pushed:   none
       PDA::Production.new("^(\\s|-|=)*$") do |md, pda|
       end       
      ]

    # Productions (including BASE_PRODUCTIONS) that all netstat_v_*
    # parsers for ethernet adapters need.
    ENT_PRODUCTIONS =
      [
       # Sample Match:   |  Elapsed Time: 0 days 0 hours 0 minutes 0 seconds
       # States Matched: :all
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # The SEA and vlan has an extra timestamp which is always
       # zero.  This Ignores it if Elapsed Time is already set
       PDA::Production.new("^\\s*(?<field>Elapsed Time):\\s+(?<value>0 days 0 hours 0 minutes 0 seconds)\\s*$") do |md, pda|
         field = md[:field]
         value = md[:value].strip # delete trailing white space from value
         ret = pda.target
         if ret.key?(field) || pda.state != :normal
           logger.debug { "Skipping #{md[0]}" }
         else
           ret[field] = value
         end
       end,
       
       # Sample Match:   |Driver Flags: Up Broadcast Simplex 
       # States Matched: :normal
       # New State:      :driverFlags
       # State Pushed:   yes
       # States Popped:  0
       # Driver Flags is followed by a sequence of flag names which are
       # put into an array.
       PDA::Production.new("^(?<field>Driver Flags):\\s+(?<flags>\\S.*)$", [:normal], :driverFlags) do |md, pda|
         field = md[:field]
         value = md[:flags].split
         pda.target[field] = value
         pda.push(value)
       end,
       
       # Sample Match:   |  	Limbo 64BitSupport ChecksumOffload 
       # States Matched: :driverFlags
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Driver Flags has flags split across multiple lines.  This
       # production adds the flags found in the second and subsequent
       # lines.
       PDA::Production.new("^\\s*(?<flags>\\S.*)$", [:driverFlags]) do |md, pda|
         flags = md[:flags].split
         pda.target.push(*flags)
         logger.debug { "Driver flags now #{pda.target}" }
       end,
       
       # Sample Match:   |empty line
       # States Matched: :driverFlags
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  1
       # Driver Flags end with a blank line.
       PDA::Production.new("^\\s*$", [:driverFlags]) do |md, pda|
         logger.debug("Popping #{pda.state} state")
         pda.pop(1)
       end,
       
       # Sample Match:   |Hardware Address: e4:1f:13:d8:28:c4
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # Specifically for matching a value that is a MAC address with
       # each byte can be one or two hex characters.
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>\\h\\h?:\\h\\h?:\\h\\h?:\\h\\h?:\\h\\h?:\\h\\h?)$", [:normal]) do |md, pda|
         field = md[:field].strip
         value = md[:value].strip
         pda.target[field] = value
       end,

       # Sample Match:   |Transmit Statistics:                          Receive Statistics:
       # States Matched: :normal
       # New State:      :entTwoColumn
       # State Pushed:   yes
       PDA::Production.new("^\\s*(?<left>Transmit Statistics):\\s*(?<right>Receive Statistics):\\s*$", [:normal], :entTwoColumn) do |md, pda|
         left = md[:left]
         right = md[:right]
         lval = WriteOnceHash.new
         rval = WriteOnceHash.new
         ret = pda.target
         ret[left] = lval
         ret[right] = rval
         value = { left: lval, right: rval, parent: ret }
         pda.push(value)
       end,
       
       # Sample Match:   |Packets: 359754                               Packets: 272450
       # States Matched: :entTwoColumn
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Pick up the two column ENT output where both columns are
       # present.  The two values are assumed to be integers.
       PDA::Production.new("^\\s*(?<lfield>\\S[^:]*):\\s*(?<lval>-?\\d+)\\s+(?<rfield>\\S[^:]*):\\s+(?<rval>-?\\d+)\\s*$", [:entTwoColumn]) do |md, pda|
         lfield = md[:lfield].strip
         lval = md[:lval].to_i
         rfield = md[:rfield].strip
         rval = md[:rval].to_i
         left = pda.target.fetch(:left)
         right = pda.target.fetch(:right)
         left[lfield] = lval
         right[rfield] = rval
       end,
       
       # Sample Match:   |                                              Bad Packets: 0
       # States Matched: :entTwoColumn
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Two column ENT output has lines with only the Receive state.
       # These start with white space.
       PDA::Production.new("^\\s+(?<rfield>Bad Packets|Maximum Buffers Per Interrupt|Average Buffers Per Interrupt|System Buffers):\\s*(?<rval>-?\\d+)$", [:entTwoColumn]) do |md, pda|
         rfield = md[:rfield]
         rval = md[:rval].to_i
         right = pda.target.fetch(:right)
         right[rfield] = rval
       end,
       
       # Sample Match:   |Multiple Collision Count: 0
       # States Matched: :entTwoColumn
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Two column ENT output has fields for Transmit only.  These
       # lines do not have any leading white space.
       PDA::Production.new("^(?<lfield>\\S[^:]+):\\s+(?<lval>-?\\d+)\\s*$", [:entTwoColumn]) do |md, pda|
         lfield = md[:lfield]
         lval = md[:lval].to_i
         left = pda.target.fetch(:left)
         left[lfield] = lval
       end,
       
       # Sample Match:   |Elapsed Time: 0 days 0 hours 38 minutes 35 seconds
       # States Matched: :entTwoColumn
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # The mustang entstat output blurts out a timestamp here
       # instead of where it should be (and its not full of zeros so
       # its a valid time stamp)... Sigh.
       PDA::Production.new("^(?<lfield>\\S[^:]+):\\s+(?<lval>[^: ]*[^:]*)\\s*$", [:entTwoColumn]) do |md, pda|
         lfield = md[:lfield].strip
         lval = md[:lval].strip
         parent = pda.target.fetch(:parent)
         parent.delete(lfield)
         parent[lfield] = lval
       end,
       
       # Sample Match:   |General Statistics:
       # States Matched: :entTwoColumn
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  1
       # End of two column ent mode
       PDA::Production.new("^\\s*(?<field>General Statistics:)\\s*$", [:entTwoColumn]) do |md, pda|
         pda.pop(1)
       end,

       # The LACP stanzas that 802.3ad aggregation adds to each
       # entstat is parsed here.  For the most part, everything works
       # except for the Actor State and Partner State.  Those need to
       # be nested down a level.  They end with the first blank line.

       # Sample Match:   |IEEE 802.3ad Port Statistics:
       # States Matched: :all
       # New State:      :normal
       # State Pushed:   none
       # States Popped:  Variable
       # The 'IEEE 802.3ad Port Statistics:' line tells us we are
       # about to start the LACP statistics for this adapter.  No
       # matter what state we are in, we need to pop the states until
       # we get to the :normal (top level) state.  The match is very
       # strict but might need to be loosened up a bit.
       PDA::Production.new("^IEEE 802.3ad Port Statistics:$") do |md, pda|
         pda.pop(1) while pda.state != :normal
       end,
       
       # Sample Match:   |	Actor State: 
       # States Matched: :normal
       # New State:      :LACP_State
       # State Pushed:   yes
       # States Popped:  0
       # Matched the Actor State: and Partner State: lines
       PDA::Production.new("^\\s*(?<field>(Actor|Partner) State):\\s*$", [:normal], :LACP_State) do |md, pda|
         field = md[:field]
         value = WriteOnceHash.new
         pda.target[field] = value
         pda.push(value)
       end,
       
       # Sample Match:   |		LACP activity: Active
       # States Matched: :LACP_State
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # All the entries during LACP_State is field: value where value
       # is not an integer
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>[^: ]*[^:]*)$", [:LACP_State]) do |md, pda|
         field = md[:field].strip
         value = md[:value].strip
         pda.target[field] = value
       end,
       
       # Sample Match:   |  <empty line>
       # States Matched: :LACP_State
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  1
       # empty line is the end of LACP_State
       PDA::Production.new("^\\s*$", [:LACP_State]) do |md, pda|
         pda.pop(1)
       end
      ] + BASE_PRODUCTIONS

    # same as []= for hash except it will fail if the field already
    # exists in the hash.  All of this is to just make sure that the
    # parsers are actually correctly parsing.
    def []=(field, value)
      fail "Overwriting value #{field}" if key?(field)
      logger.debug { "Adding field: '#{field}' = '#{value}'" }
      super
    end

    def parse
      pda = PDA.new(self, productions)
      lineno = 0
      @text.each_line do |line|
        lineno += 1
        line.chomp!
        begin
          matched = pda.match_productions(line)
          unless matched == true
            original_state = pda.state
            until (matched == true) || pda.stack.size == 0
              from = pda.state
              pda.pop(1)
              logger.debug {  "popping due to unmatched from #{from} to #{pda.state}" }
              matched = pda.match_productions(line)
            end
            unless matched == true
              pda.state = original_state
              fail "Miss: '#{line}'"
            end
          end
        rescue => e
          new_message = e.message.split("\n").insert(1, "line: #{lineno}\nstate: #{pda.state}\n#{line}\n#{e.message}").join("\n")
          new_e = e.exception(new_message)
          new_e.set_backtrace(e.backtrace)
          raise new_e
        end
      end
      self
    end

    # A "virtual" function in the Ruby sense.
    def productions
      fail "Please override this method"
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
