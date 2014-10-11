require "netstat_v"
require "write_once_hash"
require "stringio"
require "pda"

# Parsers the output from netstat -d entN where entN is a elxent
# adapter.
class Netstat_v_elxent < DotFileParser::Base
  include Logging
  # The log level that Netstat_v_elxent uses:
  LOG_LEVEL = Logger::INFO

  def initialize(text)
    productions =
      [
       # Sample Match:   |Receive statistics for RXQ number: 2
       # States Matched: :normal and :elxentQStats
       # New State:      :elxentQStats
       # State Pushed:   yes
       # States Popped:  1 if already in :elxentQStats state
       # This starts a new group so subsequent fields are added into
       # (for example) "Receive statistics for RXQ number"[2]
       PDA::Production.new("^(?<field>Receive statistics for RXQ number|Transmit statistics for TXQ number):\\s+(?<index>\\d+)\\s*$", [:normal, :elxentQStats], :elxentQStats) do |md, pda|
         field = md[:field]
         index = md[:index].to_i
         pda.pop(1) unless pda.state == :normal
         ret = pda.target
         ret[field] ||= []
         fail "Overwriting value #{field}[#{index}]" if ret[field][index]
         value = WriteOnceHash.new
         ret[field][index] = value
         logger.debug { "Starting #{field}[#{index}]" }
         pda.push(value)
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
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>\\d+)\\s*$", [:elxentQStats]) do |md, pda|
         field = md[:field].strip
         value = md[:value].to_i
         pda.target[field] = value
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
       
       # Sample Match:   |Adapter Reset Count: 0
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # For lines with exactly one colon and the value is an integer.
       # Leading white space is allowed.  Text before colon is
       # md[:field].  Text after colon is md[:value].  Leading and
       # trailing white space from both are stripped.  Value can not
       # be empty and is converted to an integer.
       PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>\\d+)\\s*$", [:normal]) do |md, pda|
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

Netstat_v::Parsers.instance.add(Netstat_v_elxent, "PCIe2 2-port 10GbE SR Adapter")
