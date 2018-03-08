require_relative 'logging'
require_relative 'file_parser'
require_relative 'item'
require_relative 'instfix'

# Parses the instfix.out file produced by perfpmr
class InstfixOutParser < FileParser
  def parse
    # HACMP snaps have a file called instfix.out which is not what I'm
    # looking for
    return if %r{hacmp/lppinfo/instfix\.out}.match(@io.path)
    name = @io.path.sub(/\A.*\//, '')
    item = @db.create_item(name)
    each_line do |line|
      line.chomp!
      fields = line.split(':')
      instfix = @db.create_item('instfix')
      name = fields.shift
      instfix[:fileset] = fields.shift
      instfix[:required] = fields.shift
      instfix[:installed] = fields.shift
      instfix[:status] = fields.shift
      instfix[:abstract] = fields.shift
      item[name] = instfix
    end
  end
end

Snapper.add_file_parsing_patterns(%r{instfix\.out} => InstfixOutParser)
