require_relative "item"
require_relative 'logging'

class Errpt < Item
  def print(options, indent = 0, string = "")
    if options.level <= 5
      text = "%*s %s" % [ -22, label, date_time ]
      output(options, indent, text)
    else
      self.to_text.each_line do |line|
        output(options, indent, line)
      end
    end
  end
end
