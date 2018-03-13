require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'
require_relative 'parse_error'

class LsvirtOutParser < FileParser
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  SVSA_REGEXP = /\ASVSA +Physloc +Client Partition ID *\Z/
  SVEA_REGEXP = /\ASVEA +Physloc *\Z/
  VNIC_REGEXP = /\AName +Physloc +ClntID ClntName +ClntOS *\Z/
  NAME_REGEXP = /\Aname +status +description *\Z/
  DASH_REGEXP = /\A[- ]+\Z/
  BLNK_REGEXP = /\A *\Z/

  def parse
    @history = []
    @lines = @io.each_line
    if @io.respond_to?(:basename)
      name = @io.basename.to_s
    else
      name = "LsvirtOut"
    end
    mid_record = false
    history = []
    loop do
      case next_line
      when BLNK_REGEXP          # skip empty lines
        next

      when SVSA_REGEXP
        record = @db.create_item(name)
        mid_record = true
        raise "Dashes expected" unless DASH_REGEXP.match(next_line)
        record[:svsa], record[:vir_physloc], record[:client_id] = next_line.split
        raise "Blanks expected" unless BLNK_REGEXP.match(next_line)
        until BLNK_REGEXP.match(next_line)
          if md = /\A(?<field>.*\S)\s +(?<value>\S+)\Z/.match(@line)
            record[md[:field]] = md[:value]
          end
        end
        mid_record = false

      when SVEA_REGEXP
        record = @db.create_item(name)
        mid_record = true
        raise "Dashes expected" unless DASH_REGEXP.match(next_line)
        record[:svea], record[:vir_physloc] = next_line.split
        raise "Blanks expected" unless BLNK_REGEXP.match(next_line)
        if (md = /\A(?<field>SEA)\s+(?<value>.*)\Z/.match(next_line))
          record[md[:field]] = md[:value]
        end
        until BLNK_REGEXP.match(next_line)
          if md = /\A(?<field>.*\S)\s +(?<value>\S+)\Z/.match(@line)
            record[md[:field]] = md[:value]
          end
        end
        mid_record = false
        
      when VNIC_REGEXP
        record = @db.create_item(name)
        mid_record = true
        raise "Dashes expected" unless DASH_REGEXP.match(next_line)
        record[:vnic], record[:vir_physloc], record[:clntid], record[:clntname], record[:clntos]  = next_line.split
        raise "Blanks expected" unless BLNK_REGEXP.match(next_line)
        until BLNK_REGEXP.match(next_line)
          if md = /\A(?<field>[^:]+):(?<value>[^:]+)\Z/.match(@line)
            record[md[:field]] = md[:value]
          end
        end
        mid_record = false
        
      when NAME_REGEXP
        # I don't see the point to parse this area since it is a
        # repeat of what I can dig out of the CuDv and other places.
        next_line until BLNK_REGEXP.match(@line)

      else
        raise ParseError.new("Unexpected text at line #{@io.lineno}", @history)
      end
    end
  rescue StopIteration
    if mid_record
      raise ParseError.new("EOF hit with unfinsihed record", @history)
    end
    unless @db[name].is_a? Array
      @db.create_item(name)
      @db.create_item(name)
      @db[name].pop(2)
    end
    self
  end

  private

  def next_line
    @line = @lines.next
    @line.chomp!
    @history.push(@line)
    @history.shift until @history.length < 5
    @line
  end
end

Snapper.add_file_parsing_patterns(%r{/lsvirt/lsvirt.out} => LsvirtOutParser)
