require "netstat_v"
require "write_once_hash"
require "stringio"
require "pda"

# Parses the entstat output from the fibre channel adapters.  This is
# for the "fcsdd" driver.
class Netstat_v_fibre < DotFileParser::Base
  include Logging
  # The log level that Netstat_v_fibre uses
  LOG_LEVEL = Logger::INFO

  def initialize(text)
    productions =
      [
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

       # Sample Match:   |Class of Service: 3
       # States Matched: :pushingULPs
       # New State:      :no_change
       # State Pushed:   no
       # States Popped:  2
       # The FC-4 TYPES (ULP mappings): section ends with the first
       # non-indented line.  This pops the pushingULPs state and the
       # fc4typesULP state and then adds the new value.
       PDA::Production.new("^(?<field>[^: ][^:]+):\\s*(?<value>\\d+)\\s*$", [:pushingULPs]) do |md, pda|
         pda.pop(2)
         field = md[:field].strip
         value = md[:value].to_i
         pda.target[field] = value
       end,

       # Sample Match:   |	Transmit Statistics	Receive Statistics
       # States Matched: :normal
       # New State:      :fcTwoColumn
       # State Pushed:   yes
       # States Popped:  0
       # Start the two column FC otuput.
       PDA::Production.new("^\\s+(?<left>\\S+ Statistics)\\s+(?<right>\\S+ Statistics)\\s*$", [:normal], :fcTwoColumn) do |md, pda|
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
       end,

       # Sample Match:   |empty line
       # States Matched: :fcTwoColumn, :indent1
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  1
       # The first empty line terminals the FC two column mode.
       PDA::Production.new("^$", [:fcTwoColumn, :indent1]) do |md, pda|
         pda.pop(1)
       end,

       # Sample Match:   |IP over FC Adapter Driver Information
       # States Matched: :normal
       # New State:      :indent1
       # State Pushed:   yes
       # States Popped:  0
       # The 'IP over FC Adapter Driver Information' line starts an
       # indented section
       PDA::Production.new("^(?<field>IP over FC Adapter Driver Information|IP over FC Traffic Statistics|FC-4 TYPES):?\\s*$", [:normal], :indent1) do |md, pda|
         field = md[:field]
         value = WriteOnceHash.new
         pda.target[field] = value
         pda.push(value)
       end,

       # Sample Match:   |  No DMA Resource Count: 0                 
       # States Matched: :indent1
       # New State:      :no_change
       # State Pushed:   none
       # For lines with exactly one colon.  Leading white space is
       # forced.  Text before colon is md[:field].  Text after colon
       # is md[:value].  Leading and trailing white space from both
       # are stripped.  value in this case must be an integer
       PDA::Production.new("^\\s+(?<field>[^: ][^:]+):\\s*(?<value>\\d+)\\s*$", [:indent1]) do |md, pda|
         field = md[:field].strip
         value = md[:value].to_i
         pda.target[field] = value
       end,

       # Sample Match:   |  Supported: 0x0000012000000000000000000000000000000000000000000000000000000000
       # States Matched: :indent1
       # New State:      :no_change
       # State Pushed:   none
       # For lines with exactly one colon.  Leading white space is
       # forced.  Text before colon is md[:field].  Text after colon
       # is md[:value].  Leading and trailing white space from both
       # are stripped.  value can not be empty
       PDA::Production.new("^\\s+(?<field>[^: ][^:]+):\\s*(?<value>\\S.*\\S)\\s*$", [:indent1]) do |md, pda|
         field = md[:field].strip
         value = md[:value]
         pda.target[field] = value
       end,

       # Sample Match:   |Class of Service: 3
       # States Matched: :indent1
       # New State:      :no_change
       # State Pushed:   none
       # States Popped:  1
       # If we are in the indent1 state, all lines should be indented.
       # If / when we hit a line that is not, that means that we pop
       # the stack and then process it like a normal line.
       PDA::Production.new("^(?<field>[^: ][^:]+):\\s*(?<value>\\d+)\\s*$", [:indent1]) do |md, pda|
         pda.pop(1)
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

Netstat_v::Parsers.instance.add(Netstat_v_fibre, "FC Adapter (adapter/pciex/df1000f114108a0)")
