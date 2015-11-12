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
  attr_accessor :options, :indent, :state, :proc
  ##
  # options are the output and command line options
  def initialize(options = {}, indent = 0, state = nil, proc = nil)
    @options, @indent, @state, @proc = options, indent, state, proc
  end

  def nest
    self.class.new(@options, @indent + 1)
  end

  def done
    @proc.call(self) if @proc
  end
end
