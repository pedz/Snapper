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
    @last_output_had_nocr = false
    @modifier = ""
    @in_list = false
  end

  # The parent that creates the context and calls item.print(context)
  # may add a modifier which the item below may incorporate in its
  # output.  Currently this is used to specify the control channel of
  # the Sea and the backup adapter for Ethchan
  def modifier(text = nil)
    if text
      @modifier = text
      self
    else
      @modifier
    end
  end

  # The level set on the command line
  def level
    @options.level
  end

  # Create a new Context nesting one level deeper.
  def nest
    self.class.new(@options, @indent + 1)
  end

  def start_list
    @in_list = true
  end

  def in_list
    @in_list
  end

  # Call the proc if one has been defined.  This method should be
  # called at the end of processing a list of items using the same
  # context.
  def done
    @proc.call(self) if @proc
    @options.puts if @last_output_had_nocr
  end

  # Does nothing if context.level is less than zero.  Sends text to
  # stdout with proper indentation and attributes applied.  text can
  # be array of strings.  If text is nil or empty, sends a blank line
  # to stdout.
  #
  # Attributes supported:
  #
  # [ :cr ] append carriage return (new line) -- default
  #
  # [ :nocr ] do not append return.  See below
  #
  # [ :black ] output text in black
  #
  # [ :red ] output text in red
  #
  # [ :green ] output text in green
  #
  # [ :yellow ] output text in yellow
  #
  # [ :blue ] output text in blue
  #
  # [ :magenta ] output text in magenta
  #
  # [ :cyan ] output text in cyan
  #
  # [ :white ] output text in white
  #
  # [ :bold ] output text in bold
  #
  # [ :bg ] background specified by the next color attribute  e.g. [
  #         :bg, :red ] would produce text with a red background but [
  #         :bg, :cr, :red ] would as well.
  #
  # Attributes apply only for the text specified (it does not change
  # state so all text has those attributes until they are cleared).
  # If :nocr is specified and text is an array of strings, it is the
  # equivalent of: output(text.join(' '), <original attributes>)
  #
  # if text is nil or empty, color attributes will have no effect.
  #
  # if text is nil or empty and :nocr is specified, no output is
  # produced.
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
    logger.debug { caller(1 .. 12).join("\n") }
    text = text.join(sep) if text.is_a? Array
    @options.printf("%s%s%s", lead, text, tail)
  end

  private

  COLORS = { black: 0, red: 1, green: 2, yellow: 3, blue: 4, magenta: 5, cyan: 6, white: 7 }
  FG = 30
  BG = 40
  BOLD = 1
  RESET = 0

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
