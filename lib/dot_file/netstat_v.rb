require "stringio"

# Class for the netstat -v output
class Netstat_v < DotFileParser::Base
  T = Regexp.new("(FIBRE CHANNEL STATISTICS REPORT: (.*)|ETHERNET STATISTICS \\((.*)\\) :|VASI STATISTICS \\((.*)\\) :)\n")

  def initialize(text)
    @text = text
    @devices = {}
    parts = text.split(T)
    unused_empty = parts.shift  # stuff before match
    while true
      whole_line, device_name, rest = parts.shift(3)
      break if whole_line.nil?
      $stderr.puts "DEVICE NAME: #{device_name}"
      @devices[device_name] = parse_lines(StringIO.new(rest))
    end
  end

  def to_json(options = {})
    @devices.to_json(options)
  end

  private

  Patterns =
    [
     ########
     # FCS specific rules

     # Sample Match:   |FC-4 TYPES
     # States Matched: :normal
     # New State:      :fc4types
     # State Pushed:   yes
     # States Popped:  0
     # Moves to a state of picking up the FC-4 TYPE values
     MatchProc.new("^(?<field>FC-4 TYPES):\\s*$", [:normal], :fc4types) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: fc4types"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,

     # Sample Match:   |FC-4 TYPES (ULP mappings):
     # States Matched: :normal
     # New State:      :fc4typesULP
     # State Pushed:   yes
     # States Popped:  0
     # Start of the FC-4 TYPES (ULP mappings) values.  This pushes one
     # state for the "FC-4 TYPES (ULP mappings)" field.  The
     # subsequent "Supported ULPs" line will push a second state for
     # its field.  "Active ULPs" will cause that state to be popped
     # and a new state pushed for the "Active ULPs" values.  The first
     # normal single field line (which is usually "Class of Service"
     # ends up popping two states.
     MatchProc.new("^(?<field>FC-4 TYPES \\(ULP mappings\\)):\\s*$", [:normal], :fc4typesULP) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: fc4typesULP"
       stack.push({state: :foo, target: value })
       # should never hit but just in case
       env[:single_field_pop_states] = 1
     end,

     # Sample Match:   |  Supported ULPs:   
     # States Matched: :fc4typesULP
     # New State:      :pushingULPs
     # State Pushed:   yes
     # States Popped:  0
     # Set up so subsequent values are pushed onto the "Supported
     # ULPs" array.
     MatchProc.new("^\\s*(?<field>Supported ULPs):\\s*$", [:fc4typesULP], :pushingULPs) do |md, env|
       field = md[:field]
       value = []
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: pushingULPs"
       stack.push({state: :foo, target: value })
       env[:single_field_pop_states] = 2
     end,

     # Sample Match:   |  Active ULPs:   
     # States Matched: :pushingULPs
     # New State:      :pushingULPs
     # State Pushed:   yes
     # States Popped:  1
     # Currently pushing values onto the "Supported ULPs" array.  This
     # rule pops that state and adds a new state so subsequent values
     # are added to the "Active ULPs" array.
     MatchProc.new("^\\s*(?<field>Active ULPs):\\s*$", [:pushingULPs], :pushingULPs) do |md, env|
       field = md[:field]
       value = []
       stack = env.fetch(:stack)
       $stderr.puts "#{__LINE__} ULP Popping stack"
       stack.pop(1)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: pushingULPs"
       stack.push({state: :foo, target: value })
     end,

     # Sample Match:   |    	Internet Protocol (IP) over Fibre Channel (IETF RFC2625) 
     # States Matched: :pushingULPs
     # New State:      :no_change
     # State Pushed:   no
     # States Popped:  0
     # The "FC-4 TYPES (ULP mappings)" output is broken into fields of
     # "Supported ULPs" and "Active ULPs".  In this state we are
     # pushing the values into an array for the particular field
     # within the "FC-4 TYPES (ULP mappings)" field.
     MatchProc.new("^\\s+(?<value>\\S[^:]+\\S)\\s*$", [:pushingULPs]) do |md, env|
       value = md[:value].strip # delete trailing white space from value
       ret = env.fetch(:stack).last.fetch(:target)
       $stderr.puts "#{__LINE__} Pushing #{value}"
       ret.push(value)
     end,

     # Sample Match:   |	Transmit Statistics	Receive Statistics
     # States Matched: :all
     # New State:      :fcTwoColumn
     # State Pushed:   yes
     # States Popped:  0
     # Start the two column FC otuput.  State ends on first empty line
     # after a field has been found.
     MatchProc.new("^\\s+(?<left>\\S+ Statistics):?\\s+(?<right>\\S+ Statistics):?\\s*$", :all, :fcTwoColumn) do |md, env|
       left = md[:left]
       right = md[:right]
       lval = {}
       rval = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{left}" if ret.key?(left)
       fail "Overwriting value #{right}" if ret.key?(right)
       $stderr.puts "#{__LINE__} Adding #{left} = #{lval} and #{right} = #{rval}"
       ret[left] = lval
       ret[right] = rval
       $stderr.puts "#{__LINE__} Pushing state :fcTwoColumn"
       stack.push({state: :foo, left: lval, right: rval })
     end,

     # Sample Match:   |Frames: 180323917       	358920289       
     # States Matched: :fcTwoColumn
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Pick up the two column FC output.  This moves us to a state
     # where an empty line will pop the stack
     MatchProc.new("^\\s*(?<field>\\S[^:]*):\\s*(?<lval>\\d+)\\s+(?<rval>\\d+)\\s*$", [:fcTwoColumn]) do |md, env|
       field = md[:field]
       lval = md[:lval].to_i
       rval = md[:rval].to_i
       stack = env.fetch(:stack)
       left = stack.last.fetch(:left)
       fail "Overwriting value #{field}" if left.key?(field)
       right = stack.last.fetch(:right)
       fail "Overwriting value #{field}" if right.key?(field)
       $stderr.puts "#{__LINE__} Adding left #{field} = #{lval} and right #{field} = #{rval}"
       left[field] = lval
       right[field] = rval
       env[:empty_line_pop_states] = 1
     end,
     
     # Sample Match:   |IP over FC Adapter Driver Information
     # States Matched: :normal
     # New State:      :FC_subparagraph
     # State Pushed:   yes
     # States Popped:  0
     # Adds subsequent fields to a common hash.  First empty line ends
     # the grouping.
     MatchProc.new("^(?<field>IP over FC Adapter Driver Information|IP over FC Traffic Statistics)\\s*$", [:normal], :FC_subparagraph) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: FC_subparagraph"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,

     ########
     # ENT specific rules

     # Sample Match:   |Transmit Statistics:                          Receive Statistics:
     # States Matched: :all
     # New State:      :entTwoColumn
     # State Pushed:   yes
     # States Popped:  0
     # start two column stats for ENT.  The FC two column has leading white space while the ENT does not.
     MatchProc.new("^(?<left>\\S+ Statistics):?\\s+(?<right>\\S+ Statistics):?\\s*$", :all, :entTwoColumn) do |md, env|
       left = md[:left]
       right = md[:right]
       lval = {}
       rval = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{left}" if ret.key?(left)
       fail "Overwriting value #{right}" if ret.key?(right)
       $stderr.puts "#{__LINE__} Adding #{left} = #{lval} and #{right} = #{rval}"
       ret[left] = lval
       ret[right] = rval
       $stderr.puts "#{__LINE__} Pushing state :entTwoColumn"
       stack.push({state: :foo, left: lval, right: rval, target: ret })
     end,

     # Sample Match:   |Packets: 359754                               Packets: 272450
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Pick up the two column ENT output where both columns are present
     MatchProc.new("^\\s*(?<lfield>\\S[^:]*):\\s*(?<lval>\\d+)\\s+(?<rfield>\\S[^:]*):\\s+(?<rval>\\d+)\\s*$", [:entTwoColumn]) do |md, env|
       lfield = md[:lfield]
       lval = md[:lval].to_i
       rfield = md[:rfield]
       rval = md[:rval].to_i
       stack = env.fetch(:stack)
       left = stack.last.fetch(:left)
       fail "Overwriting value #{lfield}" if left.key?(lfield)
       right = stack.last.fetch(:right)
       fail "Overwriting value #{rfield}" if right.key?(rfield)
       $stderr.puts "#{__LINE__} Adding left #{lfield} = #{lval} and right #{rfield} = #{rval}"
       left[lfield] = lval
       right[rfield] = rval
     end,
     
     # Sample Match:   |                                              Bad Packets: 0
     # States Matched: :all
     # New State:      :entTwoColumn
     # State Pushed:   none
     # States Popped:  0
     # Two column ENT output has one line with only the Receive state.
     MatchProc.new("^\\s+(?<rfield>Bad Packets):\\s*(?<rval>\\d+)$", [:entTwoColumn]) do |md, env|
       rfield = md[:rfield]
       rval = md[:rval].to_i
       stack = env.fetch(:stack)
       right = stack.last.fetch(:right)
       fail "Overwriting value #{rfield}" if right.key?(rfield)
       $stderr.puts "#{__LINE__} Adding right #{rfield} = #{rval}"
       right[rfield] = rval
     end,

     # Sample Match:   |Multiple Collision Count: 0
     # States Matched: :entTwoColumn
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Two column ENT output has a few trailing fields for Transmit
     # only.  This also indicates we are nearing the end of the two
     # column output so :empty_line_pop_states is set to 1.
     MatchProc.new("^(?<lfield>Multiple Collision Count|Current HW Transmit Queue Length):\\s+(?<lval>\\d+)\\s*$", [:entTwoColumn]) do |md, env|
       lfield = md[:lfield]
       lval = md[:lval].to_i
       stack = env.fetch(:stack)
       left = stack.last.fetch(:left)
       fail "Overwriting value #{lfield}" if left.key?(lfield)
       $stderr.puts "#{__LINE__} Adding left #{lfield} = #{lval}"
       left[lfield] = lval
       env[:empty_line_pop_states] = 1
     end,
     
     # Sample Match:   |Driver Flags: Up Broadcast Simplex 
     # States Matched: :normal
     # New State:      :driverFlags
     # State Pushed:   yes
     # States Popped:  0
     # Driver Flags is followed by a sequence of flag names which are
     # put into an array.
     MatchProc.new("^(?<field>Driver Flags):\\s+(?<flags>\\S.*)$", [:normal], :driverFlags) do |md, env|
       field = md[:field]
       value = md[:flags].split
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: driverFlags"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,
     
     # Sample Match:   |  	Limbo 64BitSupport ChecksumOffload 
     # States Matched: :driverFlags
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Driver Flags has flags split across multiple lines.  This rule
     # adds the flags found in the second and subsequent lines.
     MatchProc.new("^\\s*(?<flags>\\S.*)$", [:driverFlags]) do |md, env|
       flags = md[:flags].split
       env.fetch(:stack).last[:target] += flags
       $stderr.puts "#{__LINE__} Driver flags now #{env.fetch(:stack).last[:target]}"
     end,

     # Sample Match:   |Receive statistics for RXQ number: 2
     # States Matched: :normal and :elxentQStats
     # New State:      :elxentQStats
     # State Pushed:   yes
     # States Popped:  1 if already in :elxentQStats state
     # This starts a new group so subsequent fields are added into
     # (for example) "Receive statistics for RXQ number"[2]
     MatchProc.new("^(?<field>Receive statistics for RXQ number|Transmit statistics for TXQ number):\\s+(?<index>\\d+)\\s*$", [:normal, :elxentQStats], :elxentQStats) do |md, env|
       field = md[:field]
       index = md[:index].to_i
       stack = env.fetch(:stack)
       stack.pop(1) unless stack.last.fetch(:state) == :normal
       ret = stack.last.fetch(:target)
       ret[field] ||= []
       fail "Overwriting value #{field}[#{index}]" if ret[field][index]
       value = {}
       ret[field][index] = value
       $stderr.puts "#{__LINE__} Starting #{field}[#{index}]"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,

     # Sample Match:   |  Elapsed Time: 0 days 0 hours 0 minutes 0 seconds
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # The SEA has an extra timestamp which is always zero.  This
     # Ignores it if Elapsed Time is already set
     MatchProc.new("^\\s*(?<field>Elapsed Time):\\s+(?<value>0 days 0 hours 0 minutes 0 seconds)\\s*$") do |md, env|
       field = md[:field]
       value = md[:value].strip # delete trailing white space from value
       ret = env.fetch(:stack).last.fetch(:target)
       if ret.key?(field)
         $stderr.puts "#{__LINE__} Skipping #{md[0]}"
       else
         $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
         ret[field] = value
       end
     end,
     
     # Sample Match:   |General Statistics:
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for ENT
     MatchProc.new("^\\s*(?<field>General Statistics:|.*Specific Statistics:|Statistics for every adapter in the EtherChannel:)\\s*$") do |md, env|
       $stderr.puts "#{__LINE__} Ignored #{md[:field]}"
     end,

     ########
     # SEA specific rules

     # Sample Match:   |SEA Flags: 00000013
     # States Matched: :all
     # New State:      :SEA_flags
     # State Pushed:   yes
     # States Popped:  0
     # 
     MatchProc.new("^(?<field>SEA Flags):\\s*(?<value>\\h+)\\s*$", :all, :SEA_flags) do |md, env|
       # Save SEA Flags field as a hex value
       field = md[:field] + " (hex)"
       value = md[:value].hex
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding field: #{field} = #{value}"
       ret[field] = value

       # We also create a new field and push a state
       field = md[:field] + " (names)"
       value = []
       fail "overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding field: #{field} = #{value}"
       ret[field] = value
       stack.push({ state: :foo, target: value })
     end,
     
     # Sample Match:   |    < THREAD >
     # States Matched: :SEA_flags
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Pick up and push flag names
     MatchProc.new("^\\s*< (?<flag>.*) >\\s*$", [:SEA_flags]) do |md, env|
       env.fetch(:stack).last.fetch(:target).push(md[:flag])
     end,
     
     # Sample Match:   |VLAN Ids :
     # States Matched: :SEA_flags
     # New State:      :SEA_VLAN
     # State Pushed:   yes
     # States Popped:  1
     # Start looking for VLAN id lines
     MatchProc.new("^\\s*(?<field>VLAN Ids)\\s*:\\s*$", [:SEA_flags], :SEA_VLAN) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       stack.pop(1)             # Pop off SEA_flags state
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: SEA_VLAN"
       stack.push({state: :foo, target: value })
     end,

     # Sample Match:   |    ent19: 271 272 1288 4092
     # States Matched: :SEA_VLAN
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # This rule is very similar to the VEA_VLAN_IDs rule.  This rule
     # forces a space at the front so it does not match the VLAN Tag
     # line.
     MatchProc.new("^\\s+(?<field>\\S[^:]+):\\s*(?<value>\\S.+)$") do |md, env|
       field = md[:field]
       value = md[:value].strip.split
       ret = env.fetch(:stack).last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
     end,
     
     # Sample Match:   |	SEA THREADS INFORMATION
     # States Matched: :all
     # New State:      :SEA_threads
     # State Pushed:   yes
     # States Popped:  0
     MatchProc.new("^\\s*(?<field>SEA THREADS INFORMATION)\\s*$", :all, :SEA_threads) do |md, env|
       field = md[:field]
       value = []
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing :SEA_threads"
       stack.push({ state: :foo, target: value })
     end,
     
     # Sample Match:   |	Thread .............. #0
     # States Matched: :SEA_threads and :SEA_thread_gather
     # New State:      :SEA_thread_gather
     # State Pushed:   yes
     # States Popped:  1 if in :SEA_thread_gather
     MatchProc.new("^\\s*Thread[ .]*#(?<index>\\d+)\\s*$", [:SEA_threads, :SEA_thread_gather], :SEA_thread_gather) do |md, env|
       index = md[:index].to_i
       value = {}
       stack = env.fetch(:stack)
       stack.pop(1) if stack.last.fetch(:state) == :SEA_thread_gather
       ret = stack.last.fetch(:target) # should be array of threads
       fail "Overwriting value at index #{index}" if ret[index]
       $stderr.puts "#{__LINE__} Adding thread index #{index}"
       ret[index] = value
       $stderr.puts "#{__LINE__} Pushing :SEA_thread_gather"
       stack.push({ state: :foo, target: value })
     end,
     
     # Sample Match:   |    SEA Default Queue #8 
     # States Matched: :SEA_thread_gather
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Special case pattern but really just another field value pair
     MatchProc.new("^\\s*(?<field>SEA Default Queue)\\s*#(?<value>\\d+)\\s*$", [:SEA_thread_gather]) do |md, env|
       field = md[:field]
       value = md[:value].to_i
       ret = env.fetch(:stack).last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding integer field: #{field} = #{value}"
       ret[field] = value
     end,

     # Sample Match:   |High Availability Statistics:
     # States Matched: :SEA_thread_gather
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  2
     # end of thread specific statistics.
     MatchProc.new("High Availability Statistics", [:SEA_thread_gather]) do |md, env|
       env.fetch(:stack).pop(2)
     end,

     # Sample Match:   |Statistics for adapters in the Shared Ethernet Adapter ent22
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignore for now.
     MatchProc.new("^Statistics for adapters in the Shared Ethernet Adapter ent\\d+$") do |md, env|
       $stderr.puts "#{__LINE__} Ignored #{md[0]}"
     end,
     
     # Sample Match:   |Real Side Statistics
     # States Matched: :normal, :SEA_subparagraphs, and :SEA_VLAN
     # New State:      :SEA_subparagraphs
     # State Pushed:   none
     # States Popped:  1 if not in :normal
     MatchProc.new("^\\s*(?<field>Real Side Statistics|Virtual Side Statistics|Other Statistics):\\s*$", [:normal, :SEA_subparagraphs, :SEA_VLAN], :SEA_subparagraphs) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       stack.pop(1) unless stack.last.fetch(:state) == :normal
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: SEA_subparagraph"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,
     
     # Sample Match:   |Type of Packets Received:
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for SEA
     MatchProc.new("^\\s*(?<field>Type of Packets Received):\\s*$") do |md, env|
       $stderr.puts "#{__LINE__} Ignored #{md[:field]}"
     end,

     ########
     # VEA specific rules

     # Sample Match:   |Hypervisor Information  
     # States Matched: :normal
     # New State:      :VEA_information
     # Push State?:    yes
     # States Popped:  0
     # There are sub stanzas like "Transmit Buffers" that I'm going to
     # ignore for now.  Pop the stack at first blank line
     MatchProc.new("^\\s*(?<field>Hypervisor|Transmit) Information\\s*$", [:normal], :VEA_informatin) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: VEA_information"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,

     # Sample Match:   |VLAN Tag IDs:   104   105   106   201   202   203   205   209   210
     # States Matched: :all
     # New State:      :VEA_VLAN_IDs
     # State Pushed:   yes
     # States Popped:  0
     # Note that the "VLAN Tag IDs:  None" lines are matched as a
     # general text field.
     MatchProc.new("^\\s*(?<field>VLAN Tag IDs):\\s+(?<tags>\\d+(?:\\s+\\d+)*)\\s*$", :all, :VEA_VLAN_IDs) do |md, env|
       field = md[:field]
       tags = md[:tags].split
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding field: #{field} = #{tags}"
       ret[field] = tags
       $stderr.puts "#{__LINE__} Pushing state: VEA_VLAN_IDs"
       stack.push({state: :foo, target: tags })
       env[:empty_line_pop_states] = 1
     end,

     # Sample Match:   |                248   250   267   288   801   802     
     # States Matched: :VEA_VLAN_IDs
     # New State:      :no_change
     # State Pushed:   no
     # States Popped:  0
     MatchProc.new("^\\s+(?<tags>\\d+(?:\\s+\\d+)*)\\s*$", [:VEA_VLAN_IDs]) do |md, env|
       tags = md[:tags].split
       env.fetch(:stack).last[:target] += tags
       $stderr.puts "#{__LINE__} VLAN Tag IDs now #{env.fetch(:stack).last.fetch(:target)}"
     end,

     # Sample Match:   |General Statistics:
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for VEA
     MatchProc.new("^\\s*(?<field>Virtual Memory|I/O Memory|Transmit Buffers|History|Receive Information|Receive Buffers|I/O Memory Information)\\s*$") do |md, env|
       $stderr.puts "#{__LINE__} Ignored #{md[:field]}"
     end,

     # Sample Match:   |    Buffer Type              Tiny    Small   Medium    Large     Huge
     # States Matched: :all
     # New State:      :VEA_buffers
     # State Pushed:   yes
     # States Popped:  0
     MatchProc.new("^\\s+(?<field>Buffer Type)\\s+(?<tiny>\\S+)\\s+(?<small>\\S+)\\s+(?<medium>\\S+)\\s+(?<large>\\S+)\\s+(?<huge>\\S+)\\s*$", :all, :VEA_buffers) do |md, env|
       field = md[:field]
       # value is an array of hashes -- one for each of the five
       # sizes.  We put the name of the size as the :name property in
       # each hash.  Later we could convert the value to a hash using
       # the names.
       value = []
       value.push({ name: md[:tiny] })
       value.push({ name: md[:small] })
       value.push({ name: md[:medium] })
       value.push({ name: md[:large] })
       value.push({ name: md[:huge] })
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: VASI_subparagraph"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,

     # Sample Match:   |    Min Buffers              2047     4095      511       63      127
     # States Matched: :VEA_buffers
     # New State:      :no_change
     # State Pushed:   no
     # States Popped:  0
     MatchProc.new("^\\s+(?<field>\\S+(?:\\s\\S+)*)\\s+(?<tiny>\\d+)\\s+(?<small>\\d+)\\s+(?<medium>\\d+)\\s+(?<large>\\d+)\\s+(?<huge>\\d+)\\s*$", [:VEA_buffers]) do |md, env|
       field = md[:field]
       temp = []
       temp.push(md[:tiny].to_i)
       temp.push(md[:small].to_i)
       temp.push(md[:medium].to_i)
       temp.push(md[:large].to_i)
       temp.push(md[:huge].to_i)
       ret = env.fetch(:stack).last.fetch(:target)
       ret.each do |h|
         value = temp.shift
         fail "Overwriting value #{field}" if h.key?(field)
         $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
         h[field] = value
       end
     end,

     ########
     # VASI specific rules

     # Sample Match:   |Local DMA Window:
     # States Matched: :normal
     # New State:      :VSAI_subparagraph
     # Push State?:    yes
     # States Popped:  0
     MatchProc.new("^(?<field>Local DMA Window|Remote DMA Window):\\s*$", [:normal], :VASI_subparagraph) do |md, env|
       field = md[:field]
       value = {}
       stack = env.fetch(:stack)
       ret = stack.last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
       $stderr.puts "#{__LINE__} Pushing state: VASI_subparagraph"
       stack.push({state: :foo, target: value })
       env[:empty_line_pop_states] = 1
     end,

     # Sample Match:   |  Class of Service: 3
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  env[:single_field_pop_states] if non-zero
     # Note that white space may be before field.  Probably the most
     # common line of a field: value where value is an integer.
     MatchProc.new("^\\s*(?<field>\\S[^:]+):\\s*(?<value>\\d+)\\s*$") do |md, env|
       field = md[:field]
       value = md[:value].to_i

       # pop stack if needed
       single_field_pop_states = env.fetch(:single_field_pop_states)
       if single_field_pop_states > 0
         $stderr.puts "#{__LINE__} Int Field Popping #{single_field_pop_states}"
         env.fetch(:stack).pop(single_field_pop_states)
         env[:single_field_pop_states] = 0
       end

       ret = env.fetch(:stack).last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding integer field: #{field} = #{value}"
       ret[field] = value
     end,

     # Sample Match:   |  Device Type: FC Adapter (adapter/pciex/df1000f114108a0)
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  env[:single_field_pop_states] if non-zero
     # Note that white space may be before field.  Also, the above
     # pattern will match if value is a number which is by far the
     # most commong
     MatchProc.new("^\\s*(?<field>\\S[^:]+):\\s*(?<value>\\S.+)$") do |md, env|
       field = md[:field]
       value = md[:value].strip # delete trailing white space from value

       # pop stack if needed
       single_field_pop_states = env.fetch(:single_field_pop_states)
       if single_field_pop_states > 0
         $stderr.puts "#{__LINE__} Text Field Popping #{single_field_pop_states}"
         env.fetch(:stack).pop(single_field_pop_states)
         env[:single_field_pop_states] = 0
       end

       ret = env.fetch(:stack).last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding text field: #{field} = #{value}"
       ret[field] = value
     end,

     # Sample Match:   |    VRM Desired (KB)          100
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  env[:single_field_pop_states] if non-zero
     # A field with no colon.  Patter is made to be very strict
     MatchProc.new("^\\s*(?<field>\\S\\D+\\S)\\s+(?<value>\\d+)\\s*$") do |md, env|
       field = md[:field]
       value = md[:value].to_i

       # pop stack if needed
       single_field_pop_states = env.fetch(:single_field_pop_states)
       if single_field_pop_states > 0
         $stderr.puts "#{__LINE__} Text Field Popping #{single_field_pop_states}"
         env.fetch(:stack).pop(single_field_pop_states)
         env[:single_field_pop_states] = 0
       end

       ret = env.fetch(:stack).last.fetch(:target)
       fail "Overwriting value #{field}" if ret.key?(field)
       $stderr.puts "#{__LINE__} Adding integer non-colon field: #{field} = #{value}"
       ret[field] = value
     end,

     # Sample Match:   empty lines or lines with only white space and
     #                 dashes
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  env[:empty_line_pop_states] if non-zero
     MatchProc.new("^[-=\t ]*$") do |md, env|
       empty_line_pop_states = env.fetch(:empty_line_pop_states)
       if empty_line_pop_states > 0
         $stderr.puts "#{__LINE__} Empty Line Popping #{empty_line_pop_states}"
         env.fetch(:stack).pop(empty_line_pop_states)
         env[:empty_line_pop_states] = 0
       end
     end,
    ]
  
  def parse_lines(io)
    ret = {}                    # what we finally return
    env = {
      single_field_pop_states: 0,
      empty_line_pop_states: 0,
      stack: [ { state: :normal, target: ret } ]
    }
    io.each do |line|
      stack = env.fetch(:stack)
      $stderr.puts "#{__LINE__} state[#{stack.size}] is #{stack.last.fetch(:state)}"
      line.chomp!
      hit = Patterns.any? do |pat|
        pat.match(line, env)
      end
      $stderr.puts "#{__LINE__} Miss: '#{line}'" unless hit
    end
    return ret
  end
end
