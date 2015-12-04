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
  def initialize(options = {}, &proc)
    @options = Default_Options.merge(options)
    @options[:level] = @options[:level] .. @options[:level] if @options[:level].is_a? Fixnum
    if block_given?
      @proc = proc
    else
      @proc = nil
    end
  end

  # Forwards to options.level
  def level
    @options[:level]
  end

  # Not used but forwards to options.type
  def type
    @options[:type]
  end

  # Sorts based upon the level.begin
  def <=>(b)
    b.level.begin <=> level.begin
  end

  # calls the proc for the Filter with context and item.
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

  def source_location
    @proc && @proc.source_location
  end
end
