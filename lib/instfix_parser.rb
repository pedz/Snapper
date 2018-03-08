require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'

# This parses the instfix.i file in a snap.  perfpmr creates
# instfix.out which is parsed by InstfixOutParser
class InstfixParser < FileParser
  # All filesets for IZ04606 were found.
  LINE_REGEXP = /All filesets for (?<apar>\S+) were found/

  def parse
    name = @io.path.sub(/\A.*\//, '')
    item = @db.create_item(name)
    each_line do |line|
      if (md = LINE_REGEXP.match(line))
        field = md[:apar]
        value = 1
        item[field] = value
      end
    end
  end
end

Snapper.add_file_parsing_patterns(%r{/general/instfix.i} => InstfixParser)
