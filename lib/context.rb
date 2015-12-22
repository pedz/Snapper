require_relative 'logging'

# When an Item's print method is called, it sometimes needs some
# context.  For example, the print method of errpt wants to delete the
# duplicate entries.  Since print is for an individual errpt entry, it
# needs context of the previous calls.
#
# A Context is created and inject is used.  The print methods must
# return a context which is used in the next call.  The idiom is then
# to call done -- e.g.
#   enumerable_of_items.inject(context.nest) { |context, item| item.print(context) }.done
# This idiom has been sweetened with various pieces of syntatic sugar.
#
class Context
  include Logging
  # default log level is INFO
  LOG_LEVEL = Logger::INFO

  # @return [Object] An attribute that can be freely manipulated by
  #   the Filter to save whatever state it needs to save between
  #   calls.
  attr_accessor :state

  # @return [Proc] A Proc set by the Filter and is called with
  #   context.done is called.  context.done is automatically called at
  #   the end of processing a list of items.
  attr_accessor :proc

  # @param options [Options] The parsed command line options --
  #   defaults to an empty hash
  # @param indent [Fixnum] The indentation level of this context --
  #   defaults to 0.
  # @param state [Object] The initial state -- defaults to nil
  # @param proc [Proc] The block to call via {#done}.
  def initialize(options = {}, indent = 0, state = nil, proc = nil)
    @options, @indent, @state, @proc = options, indent, state, proc
    @last_output_had_nocr = false
    @modifier = ""
    @in_list = false
  end

  # The parent that creates the context and calls item.print(context)
  # may add a modifier which the item below may incorporate in its
  # output.  Currently this is used to specify the control channel of
  # the Sea and the backup adapter for Ethchan
  # @overload modifier(text)
  #   @param text [String] Sets the modifier to text.
  # @overload modifier
  #   @return [String] returns the current modifier.
  def modifier(text = nil)
    if text
      @modifier = text
      self
    else
      @modifier
    end
  end

  # @return [Fixnum] Forwards to {Options#level}.
  def level
    @options.level
  end

  # @return [Context] Creates a new Context nesting one level deeper.
  def nest
    self.class.new(@options, @indent + 1)
  end

  # Used by {Enumerable} to signify the context is now being used
  # within a list.  {Item#print} uses {Context#in_list} to not call
  # {Context#done} and puts that burden upon the entity that is
  # processing the list.
  # @see in_list
  def start_list
    @in_list = true
  end

  # Used by {Item#print} to see if {Enumerable} is currently printing
  # a list of items in which case {Context#done} is not called by
  # {Item#print} but is called by {Enumerable#print}
  # @return [Boolean] True if {#start_list} called since last call to
  #   {#done}.
  def in_list
    @in_list
  end

  # Call the proc if one has been defined.  This method should be
  # called at the end of processing a list of items using the same
  # context.  The +in_list+ state is set back to false and if the last
  # call to {#output} had +:nocr+ set, then a newline is output.
  def done
    @in_list = false
    @proc.call(self) if @proc
    @options.puts if @last_output_had_nocr
  end

  # Does nothing if context.level is less than zero.  Sends text to
  # {Options#printf} with proper indentation and attributes applied.
  # text can be array of strings.  If text is nil or empty, sends a
  # blank line to the output.
  #
  # @param text [String, Array<String>] The text to output.  If text
  #   is nil or empty, color attributes will have no effect. If text
  #   is nil or empty and :nocr is specified, no output is produced.
  # @param attrs [Array<Symbol>] A list of attributes to use during
  #   the output of the text.
  #
  #   Attributes supported:
  #  
  #   :cr:: append carriage return (new line) -- default
  #  
  #   :nocr:: do not append return.  If :nocr is specified and text is
  #           an array of strings, it is the equivalent of:
  #           <tt>output(text.join(' '), attrs)</tt>
  #  
  #   :black:: output text in black
  #  
  #   :red:: output text in red
  #  
  #   :green:: output text in green
  #  
  #   :yellow:: output text in yellow
  #  
  #   :blue:: output text in blue
  #  
  #   :magenta:: output text in magenta
  #  
  #   :cyan:: output text in cyan
  #  
  #   :white:: output text in white
  #  
  #   :bold:: output text in bold
  #  
  #   :bg:: background specified by the next color attribute
  #         e.g. <tt>[ :bg, :red ]</tt> would produce text with a red
  #         background but <tt>[ :bg, :cr, :red ]</tt> would as well.
  #    
  #   Attributes apply only for the text specified (it does not change
  #   state so all text has those attributes until they are cleared).
  # @example Output in red
  #   context.output(item.to_text, [ :red ])
  def output(text = nil, attrs = [ :cr ])
    # get edge cases out of the way
    return if level < 0
    if text.nil? || text.empty?
      unless attrs.include?(:nocr)
        @options.puts
        @last_output_had_nocr = false
      end
      return
    end
    lead, sep, tail = cvt_attrs(attrs)
    # Prints the stack of the caller for debugging purposes.
    logger.debug { caller(4 .. 15).join("\n") }
    text = text.map(&:chomp).join(sep) if text.is_a? Array
    @options.printf("%s%s%s", lead, text, tail)
  end

  private

  COLORS = { black: 0, red: 1, green: 2, yellow: 3, blue: 4, magenta: 5, cyan: 6, white: 7 }
  FG = 30
  BG = 40
  BOLD = 1
  RESET = 0

  # Converts the attrs to a 3-tuple used by {#output}.
  # @param attrs [Array<Symbol>] Same as for {#output}.
  # @return [Array(String, String, String)] The 3-tuple returns is
  #   +lead+, +sep+, and +tail+.  +lead+ comes before any text.  +sep+
  #   comes between items if text is an array.  And +tail+ comes at
  #   the end and includes the newline if appropriate.
  # @raise [RuntimeError] if an unknown attribute is passed in.
  def cvt_attrs(attrs)
    bg = false
    cr = true
    bold = false
    fg_code = nil
    bg_code = nil
    attrs.each do |attr|
      case attr
      when :black, :red, :green, :yellow, :blue, :magenta, :cyan, :white
        if bg
          bg_code = BG + COLORS[attr]
        else
          fg_code = FG + COLORS[attr]
        end
        bg = false
      when :nocr
        cr = false
      when :cr
        cr = true
      when :bg
        bg = true
      when :bold
        bold = BOLD
      else
        fail "Unknown attribute for output #{attr}"
      end
    end
    blanks = (" " * (@indent * 2))
    if @last_output_had_nocr
      lead = " "
    else
      lead = blanks
    end
    if bg_code || fg_code || bold
      lead += "\e[" + 
              [ fg_code, bg_code, bold ]
                .select { |e| e }
                .map { |e| "#{e}"}
                .join(';') +
              "m"
      tail = "\e[#{RESET}m"
    else
      tail = ""
    end
    if cr
      sep = "\n" + blanks
      tail += "\n"
      @last_output_had_nocr = false
    else
      sep = " "
      @last_output_had_nocr = true
    end
    return lead, sep, tail
  end
end
