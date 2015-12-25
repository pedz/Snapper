require_relative "entstat"

# Parsers the output from netstat -d entN where entN is an adapter
# type that is not currently known.
class EntstatGeneric < Entstat
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  GENERIC_PRODUCTIONS =
    [
      # Sample Match:   |empty line
      # States Matched: :driverFlags
      # New State:      :consumeAll
      # State Pushed:   yes
      # States Popped:  1
      # Driver Flags end with a blank line and then moves the PDA into
      # a comsume all state.
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
    ]

  # @return [Array<PDA::Production>] Lists {LACP_PRODUCTIONS} first,
  #   then {GENERIC_PRODUCTIONS} followed by {ENT_PRODUCTIONS} and
  #   {BASE_PRODUCTIONS}.  This causes the parser to find the LACP
  #   data but otherwise, everything after the driver flags is put
  #   into the +unmatched+ field.
  def productions
    LACP_PRODUCTIONS + GENERIC_PRODUCTIONS + ENT_PRODUCTIONS + BASE_PRODUCTIONS
  end

  # parses the text
  def parse
    super
  end
end
