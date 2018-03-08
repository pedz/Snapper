require_relative "file_parser"
require_relative "item"
require_relative 'logging'
require_relative 'snapper'

# Parse the netstat.int file from perfpmr
class NetstatIntParser < FileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # Currently this finds the netstat -d xxxx entries that are gathered
  # before the network run.  It feeds it to the netstat -v parser
  # since it is roughly the same output.
  def parse
    text = []
    state = :before
    each_line do |line|
      line.chomp!
      case state
      when :before              # looking for the entstat -d ..."
        state = :skip1 if /\Aentstat -d/.match(line)
      when :skip1               # should be a short line of dashes
        raise "short lines of dashes expected" unless /\A---------------\Z/.match(line)
        state = :dashes
      when :dashes              # should be a long line of dashes if device is present
        unless /\A-------------------------------------------------------------\Z/.match(line)
          state = :before
          next
        end
        text.push(line)
        state = :accum
      when :accum
        break if /\ADevice ent[0-9]+ has accounting disabled\Z/.match(line)
        break if /\ADevice ent[0-9]+ has accounting disabled\Z/.match(line)
        break if /\Anetstat/.match(line) # netstat marks the end
        if /\Aentstat -d/.match(line)
          state = :skip1
          next
        end
        text.push(line)
      end        
    end
    @db.create_item('netstat -v', text.join("\n")).parse
    self
  end
end

Snapper.add_file_parsing_patterns(%r{netstat\.int} => NetstatIntParser)
