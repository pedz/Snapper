require_relative 'logging'
require_relative 'filter'
# See alternative coding below
# require_relative 'empty_item'
require 'json'

# The base type used by most everything in the database with the
# exception of {List}, and {WriteOnceHash}.
#
# This is the class of this project that probably has way too many
# responsibilities.
class Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # A hash indexed by the same key as the main hash that contains the
  # text of the key in its original form.  For example, when
  # "Broadcast Packets" are saved in an item.
  # e.g. <tt>item['Broadcast Packets'] = 92</tt>, the actual key used
  # is <tt>broadcast_packets</tt>.  Thus you can access the
  # information as <tt>item['Broadcast Packets']</tt> (most
  # straightforward), <tt>item[broadcast_packets]</tt> (seldom done)
  # or by <tt>item.broadcast_packets</tt> (more convenient).
  # <tt>item.orig_key[broadcast_packets]</tt> allows the user to
  # retrieve the original of "Broadcast Packets" (probably for display
  # purposes).
  attr_reader :orig_key

  class << self
    # @overload add_filter(filter)
    #   Adds filter to the class.
    #   @param filter [Filter] The filter to add to the class.
    # @overload add_filter(klass, options = {}, &proc)
    #   Creates a Filter using options and proc and adds it to the
    #   class specified by klass.
    #   @param klass [String] Specifies the class to add the filter
    #     to.
    #   @param options [Hash] The options to pass to Filter.new.
    #   @param proc [Proc] The proc to pass to Filter.new.
    #   @see add_filter_to_class
    def add_filter(*args, &proc)
      if args.length == 1 && args[0].is_a?(Filter)
        local_add_filter(args[0])
      else
        add_filter_to_class(args[0], args[1], &proc)
      end
    end

    # @return [Array<Filter>] The list of filters for this class and
    #   all of its super classes that support the call.  Thus if
    #   Ethchan is a subclass of Device and Device is a subclass of
    #   Item, calling Ethchan.filters results in the filters for
    #   Ethchan followed by the filters for Device, followed by the
    #   filters for Item.
    def filters
      temp = []
      entity = self
      while entity
        temp << entity.local_filters if entity.respond_to?(:local_filters)
        entity = entity.superclass
      end
      temp.flatten
    end

    # @return [Array<Filter>] The set of filters only for this class
    #   sorted using Filter#<=>
    def local_filters
      (@filters ||= []).sort!
    end

    # Magic needed to get marshaling to work.  Many classes are
    # created during parse time.  When the dumped file is loaded
    # again, Ruby must already have those classes defined.  This is
    # the first step in the magic.  This is called when any class
    # inherits (or is a subclass) of Item.  Since all of the
    # autmatically created classes inherit from Item, this is a super
    # set of the list of classes that need to be created before the
    # marshaled snap file can be reloaded.
    #
    # This is also where the filters defined for a subclass are loaded
    # into the class.
    #
    # @see Snapper#restore
    # @param subclass [Class] The class that just subclassed the
    #   class.
    def inherited(subclass)
      children.push(subclass.to_s)
      load_filters(subclass)
    end

    # Called via {Item#inherited} to load the filters for the new
    # class when it is created.
    # @param klass [Symbol] The class to load the filters for.
    def load_filters(klass)
      logger.debug { "load #{class_hash[klass.to_s].length} filters for #{klass}" }
      class_hash[klass.to_s].each { |filter| klass.add_filter(filter) }
    end

    # This is just a convenience method to initialize children to an
    # empty array.
    def children
      @children ||= []
    end

    private

    # A new Filter is created using options and proc and added to the
    # class named by the first argument.  The first argument is
    # converted to a string if it is not one already.
    #
    # This works even before the class exists by saving the Filter in
    # a local hash and then adding them when the class is created via
    # the Item.inherited method.
    #
    # Note that it is assumed that the target of the message is Item
    # since this is a private method and the code in add_filter makes
    # sure that Item is the target before calling this method.
    #
    # Creates a Filter using options and proc and adds it to the
    # class specified by klass.
    # @param klass [String] Specifies the class to add the filter
    #   to.
    # @param options [Hash] The options to pass to Filter.new.
    # @param proc [Proc] The proc to pass to Filter.new.
    def add_filter_to_class(klass, options = {}, &proc)
      klass = klass.to_s
      filter = Filter.new(options, &proc)
      if (::Object.const_defined?(klass) &&
          (klass = ::Object.const_get(klass)) &&
          klass.respond_to?(:add_filter))
        logger.debug { "adding filter at #{proc.source_location} to #{klass} "}
        klass.add_filter(filter)
      else
        logger.debug { "storing filter at #{proc.source_location} for #{klass} "}
        class_hash[klass] << filter
      end
    end

    # Each class has its own set of filters.  This method adds Filter
    # to the class that is the target of the message.
    # e.g. Foo.add_filter(filter) will add the Filter to class Foo.
    # @param filter [Filter] The filter to add.
    def local_add_filter(filter)
      logger.debug { "local_add_filter #{filter.source_location}" }
      local_filters << filter
    end

    # Returns the class variable.
    def class_hash
      @@class_hash ||= Hash.new { |hash, key| hash[key] = [] }
    end
  end

  # In concept, prints the item.  In reality, it finds the first
  # filter from {#filters} that is valid for {Context#level} and then
  # calls that filter's {Filter#run} method.  Sets +@printed+ to true
  # after the filter is run.  Sets internal +@printing+ to true while
  # filter is running and thens it back to false when it completes.
  # @param context [Context] The context to use for printing.
  def print(context)
    unless @printing
      @printing = true
      filters(context).first(1).each do |filter|
        filter.run(context, self)
      end
    end
    @printing = false
    @printed = true
    context.done unless context.in_list
    # return context so inject can be used
    context
  rescue => e
    STDERR.puts self.class
    raise e
  end

  # @overload filters
  #   @return [Array<Filter>] returns the full list of filters
  #     returned by {Item.filters}.
  # @overload filter(context)
  #   @param context [Context] Provides the level as specified on the
  #     command line.
  #   @return [Array<Filter>] returns the list of filters returned by
  #     {Item.filter} but filtered such that {Filter#level} ===
  #     {Context#level}.  Note: {Filter#level} is a range so the test
  #     above is true if {Filter#level} contains {Context#level}.
  def filters(context = nil)
    if context
      self.class.filters.select { |filter| filter.level === context.level }
    else
      self.class.filters
    end
  end

  # creates an instance of subclass klass and moves all the instance
  # variables of the original Item into the new instance.  For
  # example, in Seas, when a Device is discovered to be a Sea, the
  # call: <tt>device.subclass(Sea)</tt> creates a new instance of Sea
  # moving all of the data from device into the new instance.
  # The +:super+ method points to the original target.
  # @param klass [Class] The class of the new item that is returned.
  # @return [Klass] A new item of class Klass.
  def subclass(klass)
    # The @hash.dup is key or we create a loop and we can't produce json
    new_item = klass.new(@text, @hash.dup, @orig_key, @db)
    new_item[:super] = self.dup
    new_item
  end

  # @param text [String] The initial value of text.  Can be added to
  #   via {#<<}.
  # @param hash [Hash] The initial value of hash.  Can be added to via
  #   {#[]=} which will also alter orig_key.
  # @param orig_key [Hash] The initial value of orig_key.
  # @param db [Db] The database instane to use.
  def initialize(text = "", hash = {}, orig_key = {}, db)
    @text = text
    @hash = hash
    @orig_key = orig_key
    @db = db
    @printed = false
    @printing = false
  end

  # @return [Boolean] true if entity has been printed
  def printed
    @printed
  end

  # If the text representation is being built up line by line then use
  # this entry.  (Not sure this is used anywhere).
  # @param line [String] a line of text.
  # @return [Item] self
  def <<(line)
    @text << line
    self
  end

  # @return [String] the text of the item.
  def to_text
    @text
  end

  # optional parse method used by some subclasses.
  # @return [Item] self
  def parse
    self
  end

  # Part of the method_missing magic.  
  # @param method [Symbol] The symbol to check.
  # @return [Boolean] true if the method matches a key in the hash or
  #   if Hash responds to the method.
  def respond_to_missing?(method, include_all)
    find_name(method) || @hash.respond_to?(method, include_all)
  end

  # Two magic things happen in here.  The first is a hash key can be
  # accessed as if it was a getter so <tt>item['dog']</tt> can be
  # accessed as <tt>item.dog</tt>.  The other piece of magic is if a
  # method that Hash responds to is called, then that method is sent
  # to the @hash instance variable.  If the result is a new hash, then
  # a new Item (of the same class as the original) is returned with
  # the original orig_key, text, and db but with the
  # new hash.  If the result is the same hash, then the method must
  # have modified the existing hash and self is returned.  Last, if
  # the method returns a different value (like +length+), then that
  # value is returned.
  # @param method [Symbol] The method that was involved upon the
  #   target.
  # @param args [Array<Object>] The arguments passed.
  # @param proc [Proc] The proc (if any) that was passed.
  def method_missing(method, *args, &proc)
    if !block_given? && args.length == 0 && @hash.has_key?(method)
      return @hash[method]
    end
    # An alternative coding leveraging EmptyItem but I'm not sure I
    # really like it.
    # Also see similar comment in HashMakeMethods
    # if !block_given? && args.length == 0 && !@hash.respond_to?(method)
    #   return @hash[method] if @hash.has_key?(method)
    #   return EmptyItem.new
    # end

    # The default is the send the message to @hash.  If the method
    # returns a hash, we check to see if it is the original hash.  If
    # it is, we return (the modified) self.  If it is not, we create a
    # new Item with the appropriate elements.  Last, if the result is
    # not a hash (e.g. length), we just return the result.
    if @hash.respond_to?(method)
      orig_hash_id = @hash.object_id
      result = @hash.send(method, *args, &proc)
      if result.class == Hash
        if result.object_id == orig_hash_id
          self
        else
          self.class.new(@text, result, @orig_key, @db)
        end
      else
        result
      end
    else
      super
    end
  end

  # In simple terms, forward the message to the hash instance variable
  # but first, key is modified by fix_key.  Also, if this call is
  # going to create a new field within the hash, the original key is
  # saved off in orig_key.  If there is already an existing value,
  # then the key is compared to the value in orig_key and if they
  # differ, an exception is thrown.
  # @param key [String] The field or key to set.
  # @param value [Object] The value to set the field to.
  # @return [Object] value is returned.
  # @raise [RuntimeError] if key would collide with an existing key.
  def []=(key, value)
    fixed_key = fix_key(key)
    if @hash.has_key?(fixed_key) && 
       unless key == @orig_key[fixed_key] || key.is_a?(Symbol)
         fail "Collision of new key #{key.inspect} with previous key #{@orig_key[fixed_key].inspect}"
       end
    else
      @orig_key[fixed_key] = key
    end
    @hash[fixed_key] = value
  end

  # @return [Boolean] true if hash has an entry for +fix_key(key)+.
  # @param key [String] The key to look up.
  def key?(key)
    @hash.key?(fix_key(key))
  end
  alias has_key? key?

  # @param key [String] passed to {#fix_key} and the result is used as
  #   the key to the local hash.
  # @return [Object] The value found at +fix_key(key)+.
  def [](key)
    @hash[fix_key(key)]
  end

  # An enumerator that produces a flat set of values.
  # @param nesting [Array<String>] The starting nesting to use.
  # @return [Array<Array(String, Object)>] An array of two element
  #   items: the first element is the flattened key.  The second
  #   element is value.
  def flat_keys(nesting = [])
    flatten_keys(self, nesting)
  end

  # @param options [Hash] The usual options passed to +to_json+.
  # @return [String] The JSON representation of the target.  The
  #   internal hash, the text, and the original keys are marshaled
  #   out.
  def to_json(options = {})
    temp = @hash.dup
    temp[:text] = @text
    temp[:orig_key] = @orig_key
    temp.to_json(options)
  end

  private

  # The magic behind flat_keys: a lazy recursive enumerator.
  # @param thing [Item, Array, Hash, other] The entity to return the
  #   flat keys for.
  # @param nesting [Array<String>] The list of keys needed to get to
  #   +thing+.
  # @return (see #flat_keys)
  def flatten_keys(thing, nesting = [])
    Enumerator.new do |yielder|
      if thing.is_a?(Array)
        thing.each_with_index do |value, index|
          flatten_keys(value, nesting.dup.push(index)).each { |h| yielder << h }
        end
      elsif thing.is_a?(Hash)
        thing.each_pair do |key, value|
          flatten_keys(value, nesting.dup.push(key)).each { |h| yielder << h }
        end
      elsif thing.is_a?(Item)
        if thing.keys.empty?
          yielder << [ nesting.join(','), "<not parsed>"]
        else
          thing.each_pair do |key, value|
            flatten_keys(value, nesting.dup.push(thing.orig_key[key])).each { |h| yielder << h }
          end
        end
      else
        yielder << [ nesting.join(','), thing ]
      end
    end.lazy
  end

  # converts key to lowercase and replaces all characters that are not
  # letters, digits, or the underscore character with the underscore
  # character.
  # @param key [String, Symbol] The original key as passed in to the
  #   public method.
  # @return [Symbol] key, to_s, downcase, replace non-alphanumerics
  #   with underscore, then convert to Symbol.
  def fix_key(key)
    key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
  end

  # @param method [Symbol] the method to find.
  # @return [Boolean] not sure why but returns method if
  #   +has_key?(method)+ returns true and nil otherwise
  def find_name(method)
    @hash.has_key?(method) && method
  end
end
