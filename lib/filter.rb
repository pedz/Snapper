require_relative "logging"

# Currently a vague idea.  Somehow, when given an Item and a Context,
# it will "filter" out what lines need to be printed and which ones do
# not.
class Filter
  def self.add(klass, options = {}, &proc)
    if ::Object.const_defined?(klass)
      klass = ::Object.const_get(klass)
      if klass.respond_to?(:add_filter)
        klass.add_filter(Filter.new(options, &proc))
      end
    end
  end

  Default_Options = {
    level: 1 .. 10,
    type: :key_value,
    key: /.*/,
    value: /.*/
  }

  def initialize(options = {}, &proc)
    @options = Default_Options.merge(options)
    @options[:level] = @options[:level] .. @options[:level] if @options[:level].is_a? Fixnum
    if block_given?
      @proc = proc
    else
      @proc = nil
    end
  end

  def level
    @options[:level]
  end

  def type
    @options[:type]
  end

  def <=>(b)
    b.level.begin <=> level.begin
  end

  def run(context, item)
    if @proc
      @proc.call(context, item)
    end
  end
end
