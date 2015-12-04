require_relative "logging"

# A class used to control how output is generated (or filtered).  A
# filter has a range of levels that it is active for.  It also has a
# Proc that is invoked to produce the desired output.
class Filter
  class << self
    # Creates a new Filter passing options and proc and then adds it to
    # the class specified by klass.
    def add(klass, options = {}, &proc)
      klass = klass.to_s
      filter = Filter.new(options, &proc)
      if (::Object.const_defined?(klass) &&
          (klass = ::Object.const_get(klass)) &&
          klass.respond_to?(:add_filter))
        klass.add_filter(filter)
      else
        hash[klass] << filter
      end
    end

    def load_filters(klass)
      hash[klass.to_s].each { |filter|
        klass.add_filter(filter) }
    end

    private

    def hash
      @hash ||= Hash.new { |hash, key| hash[key] = [] }
    end

  end
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
      @proc.call(context, item)
    end
  end
end
