require_relative 'logging'
require_relative 'item'

class Device < Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Device uses.

  def initilize
    super
    self[:printed] = false
  end

  SKIP_LINES = /\A=+\Z/
  def print(context)
    unless printed
      output(context, "#{cudv.name} #{cudv.ddins}")

      errpt && errpt.print_list(context.nest)

      if context.options.level > 2
        entstat && entstat.to_text.each_line do |line|
          output(context.nest, line) unless SKIP_LINES.match(line)
        end
      end

      if context.options.level > 3
        lsattr_el && lsattr_el.to_text.each_line do |line|
          output(context.nest, line)
        end
      end
    end
    context
  end
end
