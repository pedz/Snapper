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
  def print(options, indent = 0, prefix = "")
    unless printed
      output(options, indent, "#{cudv.name} #{cudv.ddins}")
      indent += 1

      if options.level > 1
        @first = nil
        @last = nil
        @count = -1
        errpt && errpt.each do |err|
          foo(options, indent, prefix, err)
        end
        foo(options, indent, prefix, nil)
      end

      if options.level > 2
        entstat && entstat.to_text.each_line do |line|
          output(options, indent, line) unless SKIP_LINES.match(line)
        end
      end

      if options.level > 3
        lsattr_el && lsattr_el.to_text.each_line do |line|
          output(options, indent, line)
        end
      end
    end
  end

  private

  def foo(options, indent, prefix, err)
    if @first && err && @first.label == err.label
      @count += 1
      @last = err
    else
      if @last
        if (@count > 0)
          output(options, indent + 1, "#{@count} duplicates removed")
        end
        @last.print(options, indent, prefix)
        @last = nil
        @count = -1
      end
      err.print(options, indent, prefix) if err
      @first = err
    end
  end
end
