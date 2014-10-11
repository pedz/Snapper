require_relative "netstat_v"
require_relative "pda"
require_relative "write_once_hash"
require "stringio"

# Parsers the output from netstat -d entN where entN is a vioent
# adapter.
class Netstat_v_vioent < DotFileParser::Base
  include Logging
  # The log level that Netstat_v_vioent uses:
  LOG_LEVEL = Logger::INFO

  def initialize(text)
    productions =
      [
       # Sample Match:   |empty line
       # States Matched: :hyperInfo
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # During the Hypervisor Infor mode, empty lines are ignored
       PDA::Production.new("^\\s*$", [:hyperInfo]) do |md, pda|
       end,
       
       # Sample Match:   |    Buffer Type              Tiny    Small   Medium    Large     Huge
       # States Matched: :hyperInfo
       # New State:      :no_change
       # State Pushed:   no
       # The "Buffer Type" line starts output for five types of
       # buffers.  The headings are soft.  At the time the "Buffer
       # Type" line is seen, we are nested under "Receive Buffers".
       # We replace that target with an array of targets, one for each
       # size.  As headings are pushed, they too make the target be an
       # array of targets.
       PDA::Production.new("^\\s*(?<field>Buffer Type)\\s*(?<sizes>\\S.*\\S)\\s*$", [:hyperInfo]) do |md, pda|
         last_indent, target, sizes = pda.target
         field = md[:field].strip
         sizes.push(*md[:sizes].split)
         new_target = []
         sizes.each do |size|
           value = WriteOnceHash.new
           target[size] = value
           new_target.push(value)
         end
         pda.pop(1)
         pda.push([last_indent, new_target, sizes])
       end,

       # Sample Match:   |Hypervisor Information
       # States Matched: :normal, and :hyperInfo
       # New State:      :hyperInfo
       # State Pushed:   yes
       # Starting with the Hypervisor Information until the end of the
       # input the output is tiered by two spaces for each level.  We
       # enter a state which creates and pops the tiers based upon the
       # indentation level.
       # The target becomes a 3-tuple with the indent level, a target,
       # and a list of sizes.  For all but the Receive Information
       # case, the target is a single hash and the list of sizes is an
       # empty array.  During the parsing of Receive Information, the
       # target is an array of hashes and sizes is an array of the
       # names of the sizes.  The oddity is that the array of targets
       # gets created when the "Buffer Type" line is found.
       # I'm probalby making this way too versatile.
       PDA::Production.new("^(?<field>(Hypervisor|Transmit|Receive|I/O Memory) Information)\\s*$", [:normal, :hyperInfo], :hyperInfo) do |md, pda|
         if pda.state == :hyperInfo
           while true
             last_indent, target, sizes = pda.target
             break if last_indent == 0
             pda.pop(1)
           end
           pda.pop(1)
         end
         field = md[:field].strip
         value = WriteOnceHash.new
         sizes = []
         pda.target[field] = value
         pda.push([0, value, sizes])
       end,

       # Sample Match:   |    Min Buffers               512      512      128       24       24
       # Sample Match:   |    VRM Minimum (KB)          100
       # States Matched: :hyperInfo
       # New State:      :no_change
       # State Pushed:   no
       # This should match lines with more than one integer field
       # separated with spaces.
       PDA::Production.new("^(?<indent>\\s*)(?<field>\\S\\D*)(?<values>(?:\\s+\\d+)+)\\s*$", [:hyperInfo]) do |md, pda|
         this_indent = md[:indent].length
         field = md[:field].strip
         values = md[:values].split.map(&:to_i)
         last_indent, target, sizes = pda.target
         unless (last_indent + 2) == this_indent
           fail "Line '#{md[0]}' has indent of #{this_indent} instead of #{last_indent + 2}" 
         end
         if sizes.empty?
           target[field] = values.shift
         else
           # This also assures us that values.size == target.size
           unless values.size == sizes.size
             fail "found #{values.size} fields while expecting #{sizes.size} fields" 
           end
           sizes.each_with_index do |size, index|
             target[index][field] = values.shift
           end
         end
       end,

       # Sample Match:   |all other lines
       # States Matched: :hyperInfo
       # New State:      :no_change
       # State Pushed:   no
       # Starting with the Hypervisor Information until the end of the
       # input the output is tiered by two spaces for each level.  We
       # enter a state which creates and pops the tiers based upon the
       # indentation level.
       PDA::Production.new("^(?<indent>\\s+)(?<field>.*)$", [:hyperInfo]) do |md, pda|
         this_indent = md[:indent].length
         field = md[:field].strip

         # if the last indent is further in than this line's indent,
         # we pop the stack until we get back to the same level
         while true
           last_indent, target, sizes = pda.target
           break if this_indent > last_indent
           pda.pop(1)
         end
         unless (last_indent + 2) == this_indent
           fail "Line '#{md[0]}' has indent of #{this_indent} instead of #{last_indent + 2}" 
         end
         if sizes.size > 0
           new_target = []
           if target[0]
             sizes.each_with_index do |size, index|
               value = WriteOnceHash.new
               target[index][field] = value
               new_target.push(value)
             end
           else
             # This happens when we get a new level 2 heading such as
             # "Virtual Memory".  target is a hash created by "Receive
             # Information".  It has "Receive Buffers" which is also a
             # hash that has "Tiny", "Small", etc.  We need to create
             # a new field as a hash and create fields within that new
             # hash called "Tiny", "Small", etc.
             value = WriteOnceHash.new
             target[field] = value
             target = value
             sizes.each do |size|
               value = WriteOnceHash.new
               target[size] = value
               new_target.push(value)
             end
           end
           pda.push([this_indent, new_target, sizes])
         else
           value = WriteOnceHash.new
           target[field] = value
           pda.push([this_indent, value, sizes])
         end
       end,

       # Sample Match:   |VLAN Tag IDs:   205   298   299  1510  1600  1601  3520  3521  3551
       # States Matched: :normal
       # New State:      :vlanTags
       # State Pushed:   yes
       # VLAN Tags is a list of integers that can continue for
       # multiple lines.  A blank line ends the list.
       PDA::Production.new("^\\s*(?<field>VLAN Tag IDs):\\s*(?<value>[0-9 ]+)\\s*$", [:normal], :vlanTags) do |md, pda|
         field = md[:field].strip
         value = md[:value].split.map(&:to_i)
         pda.target[field] = value
         pda.push(value)
       end,

       # Sample Match:   |               3552  3820  3832
       # States Matched: :vlanTags
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  0
       # Parse the (possible) continuation lines of the VLAN Tag Ids.
       PDA::Production.new("^\\s*(?<ids>\\S.*)$", [:vlanTags]) do |md, pda|
         values = md[:ids].split.map(&:to_i)
         pda.target.push(*values)
         logger.debug { "VLAN Tag IDs now #{pda.target}" }
       end,

       # Sample Match:   |empty line
       # States Matched: :vlanTags
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  1
       # VLAN Tag IDs ends with an empty line
       PDA::Production.new("^\\s*$", [:vlanTags]) do |md, pda|
         logger.debug("Popping #{pda.state} state")
         pda.pop(1)
       end,
       
       # Sample Match:   |  Enabled: 2  Queued: 0  Overflow: 0
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # Special case for three values on the same line.
       PDA::Production.new("^\\s*(?<f1>[^: ][^:]+):\\s*(?<v1>\\d+)\\s*(?<f2>[^: ][^:]+):\\s*(?<v2>\\d+)\\s*(?<f3>[^: ][^:]+):\\s*(?<v3>\\d+)\\s*$", [:normal]) do |md, pda|
         f1 = md[:f1].strip
         v1 = md[:v1].to_i
         pda.target[f1] = v1
         f2 = md[:f2].strip
         v2 = md[:v2].to_i
         pda.target[f2] = v2
         f3 = md[:f3].strip
         v3 = md[:v3].to_i
         pda.target[f3] = v3
       end,

       # Sample Match:   |  Priority: 1  Active: True
       # States Matched: :normal
       # New State:      :no_change
       # State Pushed:   none
       # Special case for two values with the second being True or
       # False
       PDA::Production.new("^\\s*(?<f1>[^: ][^:]+):\\s*(?<v1>\\d+)\\s*(?<f2>[^: ][^:]+):\\s*(?<v2>True|False)\\s*$", [:normal]) do |md, pda|
         f1 = md[:f1].strip
         v1 = md[:v1].strip
         pda.target[f1] = v1
         f2 = md[:f2].strip
         v2 = md[:v2].strip
         pda.target[f2] = v2
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

Netstat_v::Parsers.instance.add(Netstat_v_vioent, "Virtual I/O Ethernet Adapter (l-lan)")
