require_relative "logging"

# A class used to control how output is generated (or filtered).  A
# filter has a range of levels that it is active for.  It also has a
# Proc that is invoked to produce the desired output.
class Filter
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # The default options for Filter
  # Currently the only one used is level which defaults to 1 .. 10
  Default_Options = {
    level: 1 .. 10,
    type: :key_value,
    key: /.*/,
    value: /.*/
  }

  # options is a hash that currently only has :level which is a Range
  # of levels the Filter is active for.  If level is passed in as a
  # Fixnum, it is converted to a Range.  See run for how the proc is
  # invoked.
  # @param options [Hash] A hash of options.
  # @option options [Range, Fixnum] :level The range of levels that
  #   the filter is valid.  If an integer is passed it, it is
  #   converted to a range of value .. value.  Defaults to 1 .. 10.
  # @option options [Symbol] :type Currently not used but may might be
  #   used for different types of filters.
  # @option options [Regexp] :key Currently not used but might be used
  #   as a regular expression to match the keys within the item being
  #   filtered.
  # @option options [Regexp] :value Currently not used but might be
  #   used as a regular expression to match the values within the item
  #   being filtered.
  #
  # Currently the {Item#flat_keys} facility accompishes that the
  # +:type+, +:key+, and +:value+ options were intended to do.
  def initialize(options = {}, &proc)
    @options = Default_Options.merge(options)
    @options[:level] = @options[:level] .. @options[:level] if @options[:level].is_a? Fixnum
    if block_given?
      @proc = proc
    else
      @proc = nil
    end
  end

  # @return [Fixnum] Forwards to options.level
  def level
    @options[:level]
  end

  # Sorts based upon the level.begin
  def <=>(b)
    b.level.begin <=> level.begin
  end

  # calls the proc for the Filter with context and item.
  # @param context [Context] the context to pass to the proc of the
  #   filter.
  # @param item [Item] the item to pass to the proc of the filter
  # @yieldparam context [Context] the context passed in.
  # @yieldparam item [Item] the item passed in.
  def run(context, item)
    if @proc
      if logger.level == Logger::DEBUG
        original_modifier = context.modifier
        loc = @proc.source_location
        t = " from #{loc[0]}:#{loc[1]}"
        context.modifier(original_modifier + t)
      end
      @proc.call(context, item)
      if logger.level == Logger::DEBUG
        context.modifier(original_modifier)
      end
    end
  end

  # @return [Array(String, Fixnum)] Forwarded to proc.
  # @see Proc#source_location
  def source_location
    @proc && @proc.source_location
  end
end
