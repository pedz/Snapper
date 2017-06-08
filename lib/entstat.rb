require_relative "write_once_hash"
require_relative 'logging'
require_relative "pda"
require_relative "item"
require_relative "parse_error"

# @abstract Subclass and override {#productions}.  The _virtual_ base
# class for the other EntstatFoo classes.  This defines three arrays
# of productions that the subclasses can leverage as well as the
# needed parse method that the subclasses probably do not need to
# replicate.
class Entstat < Item
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO
  
  # These productions should be included in every subclass.  There are
  # four productions:
  #   1: |Real Adapter: entNN (as well as Virtual, Control and Backup)
  #   2: |burst and empty lines
  #   3: | *field: int_value
  #   4: | *field: optional_value
  BASE_PRODUCTIONS =
    [
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
      end,

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
      end
    ]
  
  # A set of productions to find and parse the LACP stanzas found at
  # the base of each real adapter's entstat output.  These also work
  # from the EntstatGeneric class so unknown adapters will still find
  # and parse the LACP stanzas.
  LACP_PRODUCTIONS =
    [
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
      PDA::Production.new("^IEEE 802.3ad Port Statistics:$", :all, :normal) do |md, pda|
        pda.pop(1) while (pda.state != :normal) && (pda.state != :consumeAll)
      end,
      
      # Sample Match:   |	Actor State: 
      # States Matched: :normal
      # New State:      :LACP_State
      # State Pushed:   yes
      # States Popped:  0
      # Matched the Actor State: and Partner State: lines
      PDA::Production.new("^\\s*(?<field>(Actor|Partner) State):\\s*$", [:normal, :consumeAll], :LACP_State) do |md, pda|
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
    ]
  
  # Productions which are entstat for ethernet specific.
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
      PDA::Production.new("^(?<field>(KIM )?Driver Flags):\\s+(?<flags>\\S.*)$", [:normal], :driverFlags) do |md, pda|
        field = "Driver Flags"  # yuk!
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
      end
    ]

  # The parse method which is usually called from the NetstatV#parse
  # method.  subclasses generally do not need to override this.  It
  # creates a PDA and drives the parser passing it each line of text.
  # @raise [RuntimeError] If a line does not match any rules.
  def parse
    pda = PDA.new(self, productions)
    lineno = 0
    history = []
    @text.each_line do |line|
      lineno += 1
      line.chomp!
      history.shift while history.length >= 5
      history.push(line)
      begin
        matched = pda.match_productions(line)
        # This is for error recovery and trying to provide as much
        # useful information to the programmer as possible.
        # Yes... this is "unless match == true"  i.e. If we failed to
        # parse.
        unless matched == true
          original_state = pda.state
          # Try popping the stack using the state at least level to
          # try and match the input line.  By default, there is no
          # error or warning when this occurs because some states do
          # not have a natural place to end.
          until (matched == true) || pda.stack.size == 0
            from = pda.state
            pda.pop(1)
            logger.debug {  "popping due to unmatched from #{from} to #{pda.state}" }
            matched = pda.match_productions(line)
          end
          # If we still did not match, fail as if we were in the
          # original state
          unless matched == true
            pda.state = original_state
            raise ParseError.new("Parsing Error in:", history)
          end
        end
      rescue => e
        unless e.is_a?(ParseError)
          backtrace = e.backtrace
          klass = e.class
          e = ParseError.new(e.message, history)
          e.add_message("#{klass} occurred in:")
          e.set_backtrace(backtrace)
        end
        # As the exception unwinds the stack, we add in tidbits to the
        # message to help us locate where we were in the parse.
        e.add_message("line offset within device entry: #{lineno}; state: #{pda.state}")
        raise e
      end
    end
    self
  end
  
  # @return [Array<PDA::Production>] A "virtual" function in the Ruby
  #   sense.  This must be overridden by all of the subclasses.
  #   Generally, they want to define a list of productions and then
  #   append {ENT_PRODUCTIONS}, {LACP_PRODUCTIONS}, and
  #   {BASE_PRODUCTIONS} (in that order).
  # @raise [RuntimeError] if the method is not overridden.
  def productions
    fail "Please override this method"
  end
end
