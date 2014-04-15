
# Class for the netstat -v output
class Netstat_v < DotFileParser::Base
  T = Regexp.new("(FIBRE CHANNEL STATISTICS REPORT: (.*)|ETHERNET STATISTICS \\((.*)\\) :|VASI STATISTICS \\((.*)\\) :)\n")

  def initialize(text)
    @text = text
    parts = text.split(T)
    unused_empty = parts.shift  # stuff before match
    while true
      whole_line, device_name, rest = parts.shift(3)
      break if whole_line.nil?
      # puts device_name
      # puts rest.match('.*')
    end
  end
end
