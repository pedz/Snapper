require_relative "netstat_v"
require_relative "pda"
require_relative "write_once_hash"
require "stringio"

# Parsers the output from netstat -d entN where entN is a sea
# adapter.
class Netstat_v_sea < DotFileParser::Base
  include Logging
  # The log level the Netstat_v uses.
  LOG_LEVEL = Logger::INFO

  def initialize(text)
    productions =
      [
       # Sample Match:   |SEA Flags: 00000013
       # States Matched: :normal
       # New State:      :SEA_flags
       # State Pushed:   yes
       # States Popped:  0
       # 
       PDA::Production.new("^(?<field>SEA Flags):\\s*(?<value>\\h+)\\s*$", [:normal], :SEA_flags) do |md, pda|
         # Save SEA Flags field as a hex value
         field = md[:field] + " (hex)"
         value = md[:value].hex
         ret = pda.target
         ret[field] = value
         
         # We also create a new field and push a state
         field = md[:field]
         value = []
         ret[field] = value
         pda.push(value)
       end,
       
       # Sample Match:   |    < THREAD >
       # States Matched: :SEA_flags
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Pick up and push flag names
       PDA::Production.new("^\\s*< (?<flag>.*) >\\s*$", [:SEA_flags]) do |md, pda|
         pda.target.push(md[:flag].strip)
       end,
       
       # Sample Match:   |VLAN Ids :
       # States Matched: :SEA_flags
       # New State:      :SEA_VLAN
       # State Pushed:   yes
       # States Popped:  1
       # Start looking for VLAN id lines
       PDA::Production.new("^\\s*(?<field>VLAN Ids)\\s*:\\s*$", [:SEA_flags], :SEA_VLAN) do |md, pda|
         field = md[:field]
         value = WriteOnceHash.new
         pda.pop(1)             # Pop off SEA_flags state
         pda.target[field] = value
         pda.push(value)
       end,
       
       # Sample Match:   |    ent19: 271 272 1288 4092
       # States Matched: :SEA_VLAN
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # This production is very similar to the VEA_VLAN_IDs production.
       # This production forces a space at the front so it does not
       # match the VLAN Tag line.
       PDA::Production.new("^\\s+(?<field>\\S[^:]+):\\s*(?<value>\\S.+)$", [:SEA_VLAN]) do |md, pda|
         field = md[:field]
         value = md[:value].strip.split.map(&:to_i)
         pda.target[field] = value
       end,
       
       # Sample Match:   |	SEA THREADS INFORMATION
       # States Matched: :SEA_subparagraphs
       # New State:      :SEA_threads
       # State Pushed:   yes
       # States Popped:  1
       PDA::Production.new("^\\s*(?<field>SEA THREADS INFORMATION)\\s*$", [:SEA_subparagraphs], :SEA_threads) do |md, pda|
         pda.pop(1)
         field = md[:field]
         value = []
         pda.target[field] = value
         pda.push(value)
       end,
       
       # Sample Match:   |	Thread .............. #0
       # States Matched: :SEA_threads and :SEA_thread_gather
       # New State:      :SEA_thread_gather
       # State Pushed:   yes
       # States Popped:  1 if in :SEA_thread_gather
       PDA::Production.new("^\\s*Thread[ .]*#(?<index>\\d+)\\s*$", [:SEA_threads, :SEA_thread_gather], :SEA_thread_gather) do |md, pda|
         index = md[:index].to_i
         value = WriteOnceHash.new
         pda.pop(1) if pda.state == :SEA_thread_gather
         pda.target[index] = value
         pda.push(value)
       end,
       
       # Sample Match:   |    SEA Default Queue #8 
       # States Matched: :SEA_thread_gather
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Special case pattern but really just another field value pair
       PDA::Production.new("^\\s*(?<field>SEA Default Queue)\\s*#(?<value>\\d+)\\s*$", [:SEA_thread_gather]) do |md, pda|
         field = md[:field]
         value = md[:value].to_i
         pda.target[field] = value
       end,
       
       # Sample Match:   |High Availability Statistics:
       # States Matched: :SEA_thread_gather
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  2
       # end of thread specific statistics.
       PDA::Production.new("High Availability Statistics", [:SEA_thread_gather]) do |md, pda|
         pda.pop(2)
       end,
       
       # Sample Match:   |Statistics for adapters in the Shared Ethernet Adapter ent22
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Ignore for now.
       PDA::Production.new("^Statistics for adapters in the Shared Ethernet Adapter ent\\d+$", [:normal]) do |md, pda|
         logger.debug { "Ignored #{md[0]}" }
       end,
       
       # Sample Match:   |Real Side Statistics
       # States Matched: :normal, :SEA_subparagraphs, and :SEA_VLAN
       # New State:      :SEA_subparagraphs
       # State Pushed:   none
       # States Popped:  1 if not in :normal
       PDA::Production.new("^\\s*(?<field>Real Side Statistics|Virtual Side Statistics|Other Statistics):\\s*$", [:normal, :SEA_subparagraphs, :SEA_VLAN], :SEA_subparagraphs) do |md, pda|
         field = md[:field]
         value = WriteOnceHash.new
         pda.pop(1) unless pda.state == :normal
         pda.target[field] = value
         pda.push(value)
       end,
       
       # Sample Match:   |Type of Packets Received:
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Ignored lines for SEA
       PDA::Production.new("^\\s*(?<field>Type of Packets Received):\\s*$", [:normal]) do |md, pda|
         logger.debug { "Ignored #{md[:field]}" }
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
         value = { left: lval, right: rval }
         pda.push(value)
       end,

       # Sample Match:   |Packets: 359754                               Packets: 272450
       # States Matched: :entTwoColumn
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Pick up the two column ENT output where both columns are
       # present.  The two values are assumed to be integers.
       PDA::Production.new("^\\s*(?<lfield>\\S[^:]*):\\s*(?<lval>\\d+)\\s+(?<rfield>\\S[^:]*):\\s+(?<rval>\\d+)\\s*$", [:entTwoColumn]) do |md, pda|
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
       PDA::Production.new("^\\s+(?<rfield>Bad Packets|Maximum Buffers Per Interrupt|Average Buffers Per Interrupt|System Buffers):\\s*(?<rval>\\d+)$", [:entTwoColumn]) do |md, pda|
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
       PDA::Production.new("^(?<lfield>\\S[^:]+):\\s+(?<lval>\\d+)\\s*$", [:entTwoColumn]) do |md, pda|
         lfield = md[:lfield]
         lval = md[:lval].to_i
         left = pda.target.fetch(:left)
         left[lfield] = lval
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
         if ret.key?(field) || pda.state == :entTwoColumn
           logger.debug { "Skipping #{md[0]}" }
         else
           ret[field] = value
         end
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
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>\\d+)\\s*$", [:normal, :SEA_subparagraphs, :SEA_thread_gather]) do |md, pda|
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

       # Sample Match:   |Statistics for adapters in the Shared Ethernet Adapter ent22
       # States Matched: :all
       # New State:      :no_change
       # State Pushed:   none
       # ignored lines
       PDA::Production.new("^Statistics for adapters in the Shared Ethernet Adapter ent\\d+\\s*$") do |md, pda|
       end,

       # Sample Match:   |Control Adapter: ent14
       # States Matched: :all
       # New State:      :no_change
       # State Pushed:   none
       # Lines which are always ignored.
       PDA::Production.new("^(Control|Real|Virtual) Adapter: ent\\d+\\s*$") do |md, pda|
       end,

       # Sample Match:   |empty lines and lines with only -'s
       # States Matched: :all
       # New State:      :no_change
       # State Pushed:   none
       PDA::Production.new("^(\\s|-)*$") do |md, pda|
       end       
      ]

    @text = text
    @result = WriteOnceHash.new
    pda = PDA.new(@result, productions)
    io = StringIO.new(text)
    lineno = 0
    io.each do |line|
      lineno += 1
      line.chomp!
      begin
        matched = pda.match_productions(line)
        fail "Miss: '#{line}'; state #{pda.state}" unless matched == true
      rescue => e
        new_e = e.exception("line: #{lineno}\n#{line}\n#{e.message}")
        new_e.set_backtrace(e.backtrace)
        raise new_e
      end
    end
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_sea, "Shared Ethernet Adapter")
