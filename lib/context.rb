require_relative 'logging'

# When an Item's print method is called, it sometimes needs some
# context.  For example, the print method of errpt wants to delete the
# duplicate entries.  Since print is for an individual errpt entry, it
# needs context of the previous calls.
#
# A Context is created and inject is used.  The print methods must
# return a context which is used in the next call.  The idiom is then
# to call done -- e.g.
#
# enumerable_of_items.inject(context.nest) { |context, item| item.print(context) }.done
#
class Context
  include Logging
  # default log level is INFO
  LOG_LEVEL = Logger::INFO

  # An attribute that can be freely manipulated by the Filter to save
  # whatever state it needs to save between calls.
  attr_accessor :state

  # A Proc set by the Filter and is called with context.done is
  # called.  context.done is automatically called at the end of
  # processing a list of items.
  attr_accessor :proc

  # options are the output and command line options
  def initialize(options = {}, indent = 0, state = nil, proc = nil)
    @options, @indent, @state, @proc = options, indent, state, proc
  end

  # The level set on the command line
  def level
    @options.level
  end

  # Create a new Context nesting one level deeper.
  def nest
    self.class.new(@options, @indent + 1)
  end

  # Call the proc if one has been defined.  This method should be
  # called at the end of processing a list of items using the same
  # context.
  def done
    @proc.call(self) if @proc
  end

  # Does nothing if context.level is less than zero.  Sends
  # text to stdout with proper indentation.  text can be multiple
  # lines.  If text is nil or unspecified, sends a blank line to
  # stdout.
  def output(text = nil)
    if level >= 0
      if text
        if text.is_a? String
          text = text.each_line
        end
        text.each do |line|
          STDOUT.puts(sprintf("%*s%s", @indent*2, "", line))
        end
      else
        STDOUT.puts("")
      end
    end
  end
end
