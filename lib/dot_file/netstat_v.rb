require "stringio"

# Class for the netstat -v output
class Netstat_v < DotFileParser::Base
  include Logging
  LOG_LEVEL = Logger::INFO

  T = Regexp.new("(FIBRE CHANNEL STATISTICS REPORT: (.*)|ETHERNET STATISTICS \\((.*)\\) :|VASI STATISTICS \\((.*)\\) :)\n")

  def initialize(text)
    @text = text
    @devices = {}
    parts = text.split(T)
    unused_empty = parts.shift  # stuff before match
    while true
      whole_line, device_name, rest = parts.shift(3)
      break if whole_line.nil?
      logger.debug { "DEVICE NAME: #{device_name}" }
      @devices[device_name] = parse_lines(StringIO.new(rest))
    end
  end

  def to_json(options = {})
    @devices.to_json(options)
  end

  private

  Productions =
    [
     ########
     # FCS specific productions

     # Sample Match:   |FC-4 TYPES
     # States Matched: :normal
     # New State:      :fc4types
     # State Pushed:   yes
     # States Popped:  0
     # Moves to a state of picking up the FC-4 TYPE values
     PDA::Production.new("^(?<field>FC-4 TYPES):\\s*$", [:normal], :fc4types) do |md, pda|
       field = md[:field]
       value = WriteOnceHash.new
       pda.target[field] = value # add new hash to existing target
       pda.push(value)           # push new state with value as target
       pda.empty_line_pop_states = 1
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
     PDA::Production.new("^(?<field>FC-4 TYPES \\(ULP mappings\\)):\\s*$", [:normal], :fc4typesULP) do |md, pda|
       field = md[:field]
       value = WriteOnceHash.new
       pda.target[field] = value
       pda.push(value)
       # should never hit but just in case
       pda.single_field_pop_states = 1
     end,

     # Sample Match:   |  Supported ULPs:   
     # States Matched: :fc4typesULP
     # New State:      :pushingULPs
     # State Pushed:   yes
     # States Popped:  0
     # Set up so subsequent values are pushed onto the "Supported
     # ULPs" array.
     PDA::Production.new("^\\s*(?<field>Supported ULPs):\\s*$", [:fc4typesULP], :pushingULPs) do |md, pda|
       field = md[:field]
       value = []
       pda.target[field] = value
       pda.push(value)
       pda.single_field_pop_states = 2
     end,

     # Sample Match:   |  Active ULPs:   
     # States Matched: :pushingULPs
     # New State:      :pushingULPs
     # State Pushed:   yes
     # States Popped:  1
     # Currently pushing values onto the "Supported ULPs" array.  This
     # production pops that state and adds a new state so subsequent
     # values are added to the "Active ULPs" array.
     PDA::Production.new("^\\s*(?<field>Active ULPs):\\s*$", [:pushingULPs], :pushingULPs) do |md, pda|
       field = md[:field]
       value = []
       pda.pop(1)
       pda.target[field] = value
       pda.push(value)
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
     PDA::Production.new("^\\s+(?<value>\\S[^:]+\\S)\\s*$", [:pushingULPs]) do |md, pda|
       value = md[:value].strip # delete trailing white space from value
       pda.target.push(value)
     end,

     # Sample Match:   |	Transmit Statistics	Receive Statistics
     # States Matched: :all
     # New State:      :fcTwoColumn
     # State Pushed:   yes
     # States Popped:  0
     # Start the two column FC otuput.  State ends on first empty line
     # after a field has been found.
     PDA::Production.new("^\\s+(?<left>\\S+ Statistics):?\\s+(?<right>\\S+ Statistics):?\\s*$", :all, :fcTwoColumn) do |md, pda|
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

     # Sample Match:   |Frames: 180323917       	358920289       
     # States Matched: :fcTwoColumn
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Pick up the two column FC output.  This moves us to a state
     # where an empty line will pop the stack
     PDA::Production.new("^\\s*(?<field>\\S[^:]*):\\s*(?<lval>\\d+)\\s+(?<rval>\\d+)\\s*$", [:fcTwoColumn]) do |md, pda|
       field = md[:field]
       lval = md[:lval].to_i
       rval = md[:rval].to_i
       left = pda.target.fetch(:left)
       right = pda.target.fetch(:right)
       left[field] = lval
       right[field] = rval
       pda.empty_line_pop_states = 1
     end,
     
     # Sample Match:   |IP over FC Adapter Driver Information
     # States Matched: :normal
     # New State:      :FC_subparagraph
     # State Pushed:   yes
     # States Popped:  0
     # Adds subsequent fields to a common hash.  First empty line ends
     # the grouping.
     PDA::Production.new("^(?<field>IP over FC Adapter Driver Information|IP over FC Traffic Statistics)\\s*$", [:normal], :FC_subparagraph) do |md, pda|
       field = md[:field]
       value = WriteOnceHash.new
       pda.target[field] = value
       pda.push(value)
       pda.empty_line_pop_states = 1
     end,

     ########
     # ENT specific productions

     # Sample Match:   |Transmit Statistics:                          Receive Statistics:
     # States Matched: :all
     # New State:      :entTwoColumn
     # State Pushed:   yes
     # States Popped:  0
     # start two column stats for ENT.  The FC two column has leading white space while the ENT does not.
     PDA::Production.new("^(?<left>\\S+ Statistics):?\\s+(?<right>\\S+ Statistics):?\\s*$", :all, :entTwoColumn) do |md, pda|
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
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Pick up the two column ENT output where both columns are present
     PDA::Production.new("^\\s*(?<lfield>\\S[^:]*):\\s*(?<lval>\\d+)\\s+(?<rfield>\\S[^:]*):\\s+(?<rval>\\d+)\\s*$", [:entTwoColumn]) do |md, pda|
       lfield = md[:lfield]
       lval = md[:lval].to_i
       rfield = md[:rfield]
       rval = md[:rval].to_i
       left = pda.target.fetch(:left)
       right = pda.target.fetch(:right)
       left[lfield] = lval
       right[rfield] = rval
     end,
     
     # Sample Match:   |                                              Bad Packets: 0
     # States Matched: :all
     # New State:      :entTwoColumn
     # State Pushed:   none
     # States Popped:  0
     # Two column ENT output has one line with only the Receive state.
     PDA::Production.new("^\\s+(?<rfield>Bad Packets):\\s*(?<rval>\\d+)$", [:entTwoColumn]) do |md, pda|
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
     # Two column ENT output has a few trailing fields for Transmit
     # only.  This also indicates we are nearing the end of the two
     # column output so :empty_line_pop_states is set to 1.
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
     # Definite end of two column ENT mode
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
       pda.empty_line_pop_states = 1
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
       pda.target += flags
       logger.debug { "#{__LINE__} Driver flags now #{pda.target}" }
     end,

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
       logger.debug { "#{__LINE__} Starting #{field}[#{index}]" }
       pda.push(value)
       pda.empty_line_pop_states = 1
     end,

     # Sample Match:   |  Elapsed Time: 0 days 0 hours 0 minutes 0 seconds
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # The SEA has an extra timestamp which is always zero.  This
     # Ignores it if Elapsed Time is already set
     PDA::Production.new("^\\s*(?<field>Elapsed Time):\\s+(?<value>0 days 0 hours 0 minutes 0 seconds)\\s*$") do |md, pda|
       field = md[:field]
       value = md[:value].strip # delete trailing white space from value
       ret = pda.target
       if ret.key?(field)
         logger.debug { "#{__LINE__} Skipping #{md[0]}" }
       else
         logger.debug { "#{__LINE__} Adding text field: #{field} = #{value}" }
         ret[field] = value
       end
     end,
     
     # Sample Match:   |PCIe2 2-port 10GbE SR Adapter (a21910071410d003) Specific Statistics:
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for ENT
     PDA::Production.new("^\\s*(?<field>.*Specific Statistics:|Statistics for every adapter in the EtherChannel:)\\s*$") do |md, pda|
       logger.debug { "#{__LINE__} Ignored #{md[:field]}" }
     end,

     ########
     # SEA specific productions

     # Sample Match:   |SEA Flags: 00000013
     # States Matched: :all
     # New State:      :SEA_flags
     # State Pushed:   yes
     # States Popped:  0
     # 
     PDA::Production.new("^(?<field>SEA Flags):\\s*(?<value>\\h+)\\s*$", :all, :SEA_flags) do |md, pda|
       # Save SEA Flags field as a hex value
       field = md[:field] + " (hex)"
       value = md[:value].hex
       ret = pda.target
       ret[field] = value

       # We also create a new field and push a state
       field = md[:field] + " (names)"
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
       pda.target.push(md[:flag])
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
     PDA::Production.new("^\\s+(?<field>\\S[^:]+):\\s*(?<value>\\S.+)$") do |md, pda|
       field = md[:field]
       value = md[:value].strip.split
       pda.target[field] = value
     end,
     
     # Sample Match:   |	SEA THREADS INFORMATION
     # States Matched: :all
     # New State:      :SEA_threads
     # State Pushed:   yes
     # States Popped:  0
     PDA::Production.new("^\\s*(?<field>SEA THREADS INFORMATION)\\s*$", :all, :SEA_threads) do |md, pda|
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
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignore for now.
     PDA::Production.new("^Statistics for adapters in the Shared Ethernet Adapter ent\\d+$") do |md, pda|
       logger.debug { "#{__LINE__} Ignored #{md[0]}" }
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
       pda.empty_line_pop_states = 1
     end,
     
     # Sample Match:   |Type of Packets Received:
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for SEA
     PDA::Production.new("^\\s*(?<field>Type of Packets Received):\\s*$") do |md, pda|
       logger.debug { "#{__LINE__} Ignored #{md[:field]}" }
     end,

     ########
     # VEA specific productions

     # Sample Match:   |Hypervisor Information  
     # States Matched: :normal
     # New State:      :VEA_information
     # Push State?:    yes
     # States Popped:  0
     # There are sub stanzas like "Transmit Buffers" that I'm going to
     # ignore for now.  Pop the stack at first blank line
     PDA::Production.new("^\\s*(?<field>Hypervisor|Transmit) Information\\s*$", [:normal], :VEA_informatin) do |md, pda|
       field = md[:field]
       value = WriteOnceHash.new
       pda.target[field] = value
       pda.push(value)
       pda.empty_line_pop_states = 1
     end,

     # Sample Match:   |VLAN Tag IDs:   104   105   106   201   202   203   205   209   210
     # States Matched: :all
     # New State:      :VEA_VLAN_IDs
     # State Pushed:   yes
     # States Popped:  0
     # Note that the "VLAN Tag IDs:  None" lines are matched as a
     # general text field.
     PDA::Production.new("^\\s*(?<field>VLAN Tag IDs):\\s+(?<tags>\\d+(?:\\s+\\d+)*)\\s*$", :all, :VEA_VLAN_IDs) do |md, pda|
       field = md[:field]
       tags = md[:tags].split
       pda.target[field] = tags
       pda.push(tags)
       pda.empty_line_pop_states = 1
     end,

     # Sample Match:   |                248   250   267   288   801   802     
     # States Matched: :VEA_VLAN_IDs
     # New State:      :no_change
     # State Pushed:   no
     # States Popped:  0
     PDA::Production.new("^\\s+(?<tags>\\d+(?:\\s+\\d+)*)\\s*$", [:VEA_VLAN_IDs]) do |md, pda|
       tags = md[:tags].split
       pda.target += tags
       logger.debug { "#{__LINE__} VLAN Tag IDs now #{pda.target}" }
     end,

     # Sample Match:   |General Statistics:
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for VEA
     PDA::Production.new("^\\s*(?<field>Virtual Memory|I/O Memory|Transmit Buffers|History|Receive Information|Receive Buffers|I/O Memory Information)\\s*$") do |md, pda|
       logger.debug { "#{__LINE__} Ignored #{md[:field]}" }
     end,

     # Sample Match:   |    Buffer Type              Tiny    Small   Medium    Large     Huge
     # States Matched: :all
     # New State:      :VEA_buffers
     # State Pushed:   yes
     # States Popped:  0
     PDA::Production.new("^\\s+(?<field>Buffer Type)\\s+(?<tiny>\\S+)\\s+(?<small>\\S+)\\s+(?<medium>\\S+)\\s+(?<large>\\S+)\\s+(?<huge>\\S+)\\s*$", :all, :VEA_buffers) do |md, pda|
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
       pda.target[field] = value
       pda.push(value)
       pda.empty_line_pop_states = 1
     end,

     # Sample Match:   |    Min Buffers              2047     4095      511       63      127
     # States Matched: :VEA_buffers
     # New State:      :no_change
     # State Pushed:   no
     # States Popped:  0
     PDA::Production.new("^\\s+(?<field>\\S+(?:\\s\\S+)*)\\s+(?<tiny>\\d+)\\s+(?<small>\\d+)\\s+(?<medium>\\d+)\\s+(?<large>\\d+)\\s+(?<huge>\\d+)\\s*$", [:VEA_buffers]) do |md, pda|
       field = md[:field]
       temp = []
       temp.push(md[:tiny].to_i)
       temp.push(md[:small].to_i)
       temp.push(md[:medium].to_i)
       temp.push(md[:large].to_i)
       temp.push(md[:huge].to_i)
       pda.target.each do |h|
         value = temp.shift
         h[field] = value
       end
     end,

     ########
     # VASI specific productions

     # Sample Match:   |Local DMA Window:
     # States Matched: :normal
     # New State:      :VSAI_subparagraph
     # Push State?:    yes
     # States Popped:  0
     PDA::Production.new("^(?<field>Local DMA Window|Remote DMA Window):\\s*$", [:normal], :VASI_subparagraph) do |md, pda|
       field = md[:field]
       value = WriteOnceHash.new
       pda.target[field] = value
       pda.push(value)
       pda.empty_line_pop_states = 1
     end,

     # Sample Match:   |  Class of Service: 3
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  pda.single_field_pop_states if non-zero
     # Note that white space may be before field.  Probably the most
     # common line of a field: value where value is an integer.
     PDA::Production.new("^\\s*(?<field>\\S[^:]+):\\s*(?<value>\\d+)\\s*$") do |md, pda|
       field = md[:field]
       value = md[:value].to_i

       # pop stack if needed
       pda.pop(pda.single_field_pop_states)
       pda.single_field_pop_states = 0

       pda.target[field] = value
     end,

     # Sample Match:   |  Device Type: FC Adapter (adapter/pciex/df1000f114108a0)
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  pda.single_field_pop_states if non-zero
     # Note that white space may be before field.  Also, the above
     # pattern will match if value is a number which is by far the
     # most commong
     PDA::Production.new("^\\s*(?<field>\\S[^:]+):\\s*(?<value>\\S.+)$") do |md, pda|
       field = md[:field]
       value = md[:value].strip # delete trailing white space from value

       # pop stack if needed
       pda.pop(pda.single_field_pop_states)
       pda.single_field_pop_states = 0

       pda.target[field] = value
     end,

     # Sample Match:   |    VRM Desired (KB)          100
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  pda.single_field_pop_states if non-zero
     # A field with no colon.  Patter is made to be very strict
     PDA::Production.new("^\\s*(?<field>\\S\\D+\\S)\\s+(?<value>\\d+)\\s*$") do |md, pda|
       field = md[:field]
       value = md[:value].to_i

       # pop stack if needed
       pda.pop(pda.single_field_pop_states)
       pda.single_field_pop_states = 0

       pda.target[field] = value
     end,

     # Sample Match:   empty lines or lines with only white space and
     #                 dashes
     # States Matched: :all
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  pda.empty_line_pop_states if non-zero
     PDA::Production.new("^[-=\t ]*$") do |md, pda|
       pda.pop(pda.empty_line_pop_states)
       pda.empty_line_pop_states = 0
     end,
    ]
  
  def parse_lines(io)
    ret = WriteOnceHash.new
    pda = PDA.new(ret, Productions)
    io.each do |line|
      line.chomp!
      logger.warn { "#{__LINE__} Miss: '#{line}'" } unless pda.match_productions(line)
    end
    return ret
  end
end
