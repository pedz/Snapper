require_relative "netstat_v"

# Parsers the output from netstat -d entN where entN is a sea
# adapter.
class Netstat_v_sea < Netstat_v::Base
  include Logging
  # The log level the Netstat_v uses.
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS as well as SEA specific productions.
  def productions
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
     
     # Sample Match:   |Type of Packets Received:
     # States Matched: :normal
     # New State:      :no_change
     # State Pushed:   none
     # States Popped:  0
     # Ignored lines for SEA
     PDA::Production.new("^\\s*(?<field>Type of Packets Received):\\s*$", [:normal]) do |md, pda|
       logger.debug { "Ignored #{md[:field]}" }
     end
    ] + ENT_PRODUCTIONS
  end
end

Netstat_v::Parsers.instance.add(Netstat_v_sea, "Shared Ethernet Adapter")
