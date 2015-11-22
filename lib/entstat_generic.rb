require_relative "entstat"

# Parsers the output from netstat -d entN where entN is an adapter
# type that is not currently known.
class Entstat_generic < Entstat
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Netstat_v uses.

  # Includes ENT_PRODUCTIONS
  def productions
    LACP_PRODUCTIONS + [
      # Sample Match:   |empty line
      # States Matched: :driverFlags
      # New State:      :consumeAll
      # State Pushed:   yes
      # States Popped:  1
      # Driver Flags end with a blank line and then puts us into a
      # comsume all state.
      PDA::Production.new("^\\s*$", [:driverFlags], :consumeAll) do |md, pda|
        logger.debug("Popping #{pda.state} state")
        pda.pop(1)
        field = 'unmatched'
        ret = pda.target
        ret[field] = List.new
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
    ] + ENT_PRODUCTIONS + BASE_PRODUCTIONS
  end
end
