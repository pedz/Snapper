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
     # fcs specific rules

     #the line FC-4 TYPES: changes state
     MatchProc.new("^FC-4 TYPES:$", [:normal], :fc4types) do |md, ret, obj|
       $stderr.puts "start fc4types state"
     end,

     # pick up the FC-4 TYPES
     MatchProc.new("[ \t]*([^:]+): *(.+)", [:fc4types]) do |md, ret, obj|
       field = "FC-4 TYPES #{md[1]}"
       $stderr.puts "p1: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if ret.has_key?(field)
       ret[field] = md[2]
     end,

     # change state from FC-4 TYPES back to normal at empty line
     MatchProc.new("^[-\t ]*$", [:fc4types], :normal) do |md, ret, obj|
       $stderr.puts "end fc4types state"
     end,

     # change state to FC-4 TYPES (ULP)
     MatchProc.new("FC-4 TYPES \\(ULP mappings\\):", [:normal], :fc4typesULP) do |md, ret, obj|
       $stderr.puts "start fc4typesULP"
     end,

     # change state to Supported ULPs
     MatchProc.new("Supported ULPs:", [:fc4typesULP], :supportedULPs) do |md, ret, obj|
       $stderr.puts "start supportedULPs"
     end,

     MatchProc.new("Active ULPs:", [:supportedULPs], :activeULPs) do |md, ret, obj|
       $stderr.puts "start activeULPs"
     end,

     # First normal looking thing, we go back to normal state
     MatchProc.new("^[ \t]*([^:]+):[ \t]*([0-9]+)[ \t]*$", [:activeULPs], :normal) do |md, ret, obj|
       field = md[1]
       $stderr.puts "p2: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if ret.has_key?(field)
       ret[field] = md[2].to_i
     end,

     # add to array of Support ULPs
     MatchProc.new("^[ \t]*([^ \t].*[^ \t])[ \t]*", [:supportedULPs]) do |md, ret, obj|
       field = "FC-4 TYPES (ULP) Supported ULPs"
       value = md[1]
       (ret[field] ||= []).push(value)
       $stderr.puts "Supported ULPs length = #{ret[field].length}; added #{value}"
     end,

     # add to array of Active ULPs
     MatchProc.new("^[ \t]*([^ \t].*[^ \t])[ \t]*", [:activeULPs]) do |md, ret, obj|
       field = "FC-4 TYPES (ULP) Active ULPs"
       value = md[1]
       (ret[field] ||= []).push(value)
       $stderr.puts "Active ULPs length = #{ret[field].length}; added #{value}"
     end,

     # start two column stats for FC
     MatchProc.new("^[ \t]+([^ \t]+) Statistics:?[ \t]+([^ \t]+) Statistics:?[ \t]*$", :all, :fcTwoColumn) do |md, ret, obj|
       left = md[1]
       right = md[2]
       $stderr.puts "start of two column output with left = #{left} and right = #{right}"
       obj[:left] = left
       obj[:right] = right
     end,

     # line with dashes is skipped
     MatchProc.new("---") do |md, ret, obj|
       $stderr.puts "skip dashes"
     end,

     # empty line stops two column (no dashes)
     MatchProc.new("^[\t ]*$", [:fcTwoColumn], :normal) do |md, ret, obj|
       $stderr.puts "back to normal state"
     end,

     # match two column FC output
     MatchProc.new("^[\t ]*([^:]+):[ \t]*([0-9]+)[ \t]+([0-9]+)[ \t]*$", [:fcTwoColumn]) do |md, ret, obj|
       f1 = "#{obj[:left]} #{md[1]}"
       f2 = "#{obj[:right]} #{md[1]}"
       raise "Overwriting value #{f1}" if ret.has_key?(f1)
       raise "Overwriting value #{f2}" if ret.has_key?(f2)
       v1 = md[2].to_i
       v2 = md[3].to_i
       ret[f1] = v1
       ret[f2] = v2
       $stderr.puts "#{f1} = #{v1} and #{f2} = #{v2}"
     end,

     # ent specific rules
     
     # start two column stats for ENT
     MatchProc.new("^([^ \t]+) Statistics:?[ \t]+([^ \t]+) Statistics:?[ \t]*$", :all, :entTwoColumn) do |md, ret, obj|
       left = md[1]
       right = md[2]
       $stderr.puts "start of two column output with left = #{left} and right = #{right}"
       obj[:left] = left
       obj[:right] = right
     end,

     # match two column FC output
     MatchProc.new("^[\t ]*([^ \t][^:]+): ([0-9]+)[ \t]+([^ \t][^:]+): ([0-9]+)[ \t]*$", [:entTwoColumn]) do |md, ret, obj|
       f1 = "#{obj[:left]} #{md[1]}"
       f2 = "#{obj[:right]} #{md[3]}"
       raise "Overwriting value #{f1}" if ret.has_key?(f1)
       raise "Overwriting value #{f2}" if ret.has_key?(f2)
       v1 = md[2].to_i
       v2 = md[4].to_i
       ret[f1] = v1
       ret[f2] = v2
       $stderr.puts "#{f1} = #{v1} and #{f2} = #{v2}"
     end,

     MatchProc.new("[ \t]+(Bad Packets): ([0-9]+)", [:entTwoColumn]) do |md, ret, obj|
       f1 = "#{obj[:left]} #{md[1]}"
       f2 = "#{obj[:right]} #{md[1]}"
       raise "Overwriting value #{f1}" if ret.has_key?(f1)
       raise "Overwriting value #{f2}" if ret.has_key?(f2)
       v1 = 0
       v2 = md[2].to_i
       ret[f1] = v1
       ret[f2] = v2
       $stderr.puts "#{f1} = #{v1} and #{f2} = #{v2}"
     end,

     # The SEA adds this line but we can't skip it all the time... Only if Elapsed Time has already been set.
     MatchProc.new("(Elapsed Time): (0 days 0 hours 0 minutes 0 seconds)") do |md, ret, obj|
       field = md[1]
       value = md[2]
       if ret.has_key?(field)
         $stderr.puts "Skipping #{md[0]}"
       else
         ret[field] = value
         $stderr.puts "Adding: #{field} = #{value}"
       end
     end,
     
     # Go back to normal state here
     MatchProc.new("(General Statistics)", [:entTwoColumn], :normal) do |md, ret, obj|
       $stderr.puts "Back to normal state: #{md[0]}"
     end,

     # suck up Driver Flags
     MatchProc.new("(Driver Flags): (.*)", :all, :driverFlags) do |md, ret, obj|
       field = md[1]
       obj[:saved_field] = field
       raise "Overwriting value #{field}" if ret.has_key?(field)
       flags = md[2].split
       ret[field] = flags
       $stderr.puts "#{field} is now #{ret[field].join(' ')} (len = #{ret[field].length})"
     end,

     MatchProc.new("^[ \t]*$", [:driverFlags], :normal) do |md, ret, obj|
       $stderr.puts "End Driver Flags"
       obj.delete(:saved_field)
     end,

     MatchProc.new(".*", [:driverFlags]) do |md, ret, obj|
       field = obj[:saved_field]
       flags = md[0].split
       ret[field] += flags
       $stderr.puts "#{field} is now #{ret[field].join(' ')} (len = #{ret[field].length})"
     end,

     # for now, just skip the "Specific Statistics" line but match it
     # in case we want to do something with it in the future
     MatchProc.new("(.*) Specific Statistics") do |md, ret, obj|
       $stderr.puts "Skipping #{md[1]} Adapter Specific Statistics"
     end,
     
     MatchProc.new("(Receive statistics for RXQ number): +([0-9]+)", [:normal, :elxentddRXQ], :elxentddRXQ) do |md, ret, obj|
       num = md[2].to_i
       $stderr.puts "Start elxent RXQ for #{num}"
       field = "RXQ"
       (ret[field] ||= [])
       raise "Overwriting value #{field}[#{num}]" if ret[field][num]
       ret[field][num] = {}
       obj[:RXQ] = num
     end,

     MatchProc.new("(Transmit statistics for TXQ number): +([0-9]+)", [:elxentddRXQ, :elxentddTXQ], :elxentddTXQ) do |md, ret, obj|
       num = md[2].to_i
       $stderr.puts "Start elxent TXQ for #{num}"
       field = "TXQ"
       (ret[field] ||= [])
       raise "Overwriting value #{field}[#{num}]" if ret[field][num]
       ret[field][num] = {}
       obj.delete(:RXQ)
       obj[:TXQ] = num
     end,

     MatchProc.new("^[- \t]*$", [:elxentddTXQ, :elxentddRXQ], :normal) do |md, ret, obj|
       $stderr.puts "end of elxent TXQ/RXQ mode"
       obj.delete(:RXQ)
       obj.delete(:TXQ)
     end,
     
     MatchProc.new("^[ \t]*([^:]+):[ \t]*([0-9]+)[ \t]*$", [:elxentddRXQ]) do |md, ret, obj|
       field = md[1]
       num = obj[:RXQ]
       temp = ret["RXQ"][num]
       $stderr.puts "RXQ[#{num}]: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if temp.has_key?(field)
       temp[field] = md[2].to_i
     end,

     MatchProc.new("^[ \t]*([^:]+):[ \t]*([0-9]+)[ \t]*$", [:elxentddTXQ]) do |md, ret, obj|
       field = md[1]
       num = obj[:TXQ]
       temp = ret["TXQ"][num]
       $stderr.puts "TXQ[#{num}]: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if temp.has_key?(field)
       temp[field] = md[2].to_i
     end,

     # VASI patterns
     MatchProc.new("(Local DMA Window|Remote DMA Window):", :all, :DMAWindow) do |md, ret, obj|
       $stderr.puts "Starting #{md[1]}"
       obj[:dmaWindow] = md[1]
     end,

     MatchProc.new("^[ \t]*([^:]+):[ \t]*([0-9]+)[ \t]*$", [:DMAWindow]) do |md, ret, obj|
       field = "#{obj[:dmaWindow]} #{md[1]}"
       $stderr.puts "p2: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if ret.has_key?(field)
       ret[field] = md[2].to_i
     end,

     MatchProc.new("^[-\t ]*$", [:DMAWindow], :normal) do |md, ret, obj|
       $stderr.puts "Back to normal state"
       obj.delete(:dmaWindow)
     end,
     
     # Common patterns
     # Lines that are just skipped
     MatchProc.new("(IP over FC Adapter Driver Information)|(IP over FC Traffic Statistics)") do |md, ret, obj|
       $stderr.puts "Skipping '#{md[0]}'"
     end,

     # very common line of:  field: int_value  all states, no state change
     MatchProc.new("^[ \t]*([^:]+):[ \t]*([0-9]+)[ \t]*$") do |md, ret, obj|
       field = md[1]
       $stderr.puts "p2: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if ret.has_key?(field)
       ret[field] = md[2].to_i
     end,

     # most common line of:  field: value  all states, no state change
     MatchProc.new("[ \t]*([^:]+): *(.+)") do |md, ret, obj|
       field = md[1]
       $stderr.puts "p1: field = #{field}, md[2] = #{md[2]}"
       raise "Overwriting value #{field}" if ret.has_key?(field)
       ret[field] = md[2]
     end,

     # Defect catch all for empty lines and bursts: all states, no state change
     MatchProc.new("^[-\t ]*$") do |md, ret, obj| # empty lines do nothing
     end,
    ]
  
  def parse_lines(io)
    ret = {}
    hash = {
    }
    state = [ :normal ]
    io.each do |line|
      line.chomp!
      hit = Patterns.any? do |pat|
        pat.match(line, ret, state, hash)
      end
      $stderr.puts "Miss: '#{line}'" unless hit
    end
    return ret
  end
end
