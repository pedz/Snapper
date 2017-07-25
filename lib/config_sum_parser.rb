require_relative 'text_file_parser'

class ConfigSumParser < TextFileParser
  include Logging
  # The default log level is INFO
  LOG_LEVEL = Logger::INFO

  def parse
    item = super
    _, after = item.to_text.split('netstat -in')
    new_text = []
    after.split("\n").each do |line|
      next if new_text.empty? && line[0 .. 4] != "Name "
      break if line.empty? && !new_text.empty?
      new_text.push(line)
    end
    @db.create_item('netstat -in', new_text.join("\n")).parse
    _, after = item.to_text.split('lslpp -ch')
    new_text = []
    after.split("\n").each do |line|
      next if new_text.empty? && line[0 .. 4] != "#Path"
      break if line.empty? && !new_text.empty?
      new_text.push(line)
    end
    @db.create_item('lslpp -lc', new_text.join("\n")).parse
  end
end

Snapper.add_file_parsing_patterns(
  %r{config\.sum} => ConfigSumParser
)
