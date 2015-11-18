require_relative 'logging'
require_relative 'item'

class Device < Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level the Device uses.

  def initilize
    super
    self[:printed] = false
  end

  def print(context)
    unless printed
      output(context, "#{cudv.name} #{cudv.ddins}")

      errpt && errpt.print_list(context.nest)
      entstat.print(context.nest) if entstat
      lsattr && lsattr.print(context.nest)
    end
    context
  end
end
