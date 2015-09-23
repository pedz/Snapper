require_relative "netstat_v"

# Parsers the output from netstat -d entN where entN is an adapter
# type that is not currently known.
class Netstat_v_generic < Netstat_v::Base
  include Logging
  # The log level the Netstat_v uses.
  LOG_LEVEL = Logger::INFO

  # Includes ENT_PRODUCTIONS
  def productions
    [
     # Sample Match:   |Adapter Specific Statistics: Unknown Device Type
     # States Matched: :all
     # New State:      :consumeAll
     # State Pushed:   yes
     # States Popped:  none
     # When we reach the adapter specific section, we change states to
     # one that just pushes all of the lines into an array called 'unmatched'
     PDA::Production.new("Adapter Specific Statistics:.*", :all, :consumeAll) do |md, pda|
       field = 'unmatched'
       ret = pda.target
       ret[field] = []
       ret[field].push(md[0])
     end,

     # Sample Match:   |everything
     # States Matched: :consumeAll
     # New State:      none
     # State Pushed:   no
     # States Popped:  none
     # When we reach the adapter specific section, we change states to
     # one that just pushes all of the lines into an array called 'unmatched'
     PDA::Production.new(".*", [:consumeAll]) do |md, pda|
       field = 'unmatched'
       ret = pda.target
       ret[field].push(md[0])
     end,
    ] + ENT_PRODUCTIONS
  end
end
