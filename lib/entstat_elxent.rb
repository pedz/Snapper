require_relative "netstat_v"
require_relative "entstat"

# Parsers the output from netstat -d entN where entN is a elxent
# adapter.
class EntstatElxent < Entstat
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  ELXENT_PRODUCTIONS =
    [
      # Sample Match:   |Receive statistics for RXQ number: 2
      # States Matched: :normal and :elxentQStats
      # New State:      :elxentQStats
      # State Pushed:   yes
      # States Popped:  1 if already in :elxentQStats state
      # This starts a new group so subsequent fields are added into
      # (for example) "Receive statistics for RXQ number"[2]
      # @raise [RuntimeError] if the same field and index are found.
      PDA::Production.new("^(?<field>Receive statistics for RXQ number|Transmit statistics for TXQ number):\\s+(?<index>\\d+)\\s*$", [:normal, :elxentQStats], :elxentQStats) do |md, pda|
        field = md[:field]
        index = md[:index].to_i
        pda.pop(1) unless pda.state == :normal
        ret = pda.target
        ret[field] ||= List.new
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
      PDA::Production.new("^\\s*(?<field>[^: ][^:]+):\\s*(?<value>-?\\d+)\\s*$", [:elxentQStats]) do |md, pda|
        field = md[:field].strip
        value = md[:value].to_i
        pda.target[field] = value
      end
    ]

  # @return [Array<PDA::Production>] {ELXENT_PRODUCTIONS},
  #   {ENT_PRODUCTIONS}, {LACP_PRODUCTIONS}, and {BASE_PRODUCTIONS}.
  def productions
    ELXENT_PRODUCTIONS + ENT_PRODUCTIONS + LACP_PRODUCTIONS + BASE_PRODUCTIONS
  end
  # @param  remove me
end

NetstatV::Parsers.instance.add(EntstatElxent, "PCIe2 2-port 10GbE SR Adapter")
NetstatV::Parsers.instance.add(EntstatElxent, "Int Multifunction Card w/ Copper SFP+ 10GbE Adapter")
NetstatV::Parsers.instance.add(EntstatElxent, "Int Multifunction Card w/ Base-TX 10/100/1000 1GbE Adapter")
