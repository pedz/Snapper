require_relative 'logging'
require_relative 'filter'
require 'json'

# The base type used by most everything in the database with the
# exception of List and WriteOnceHash.
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

  # Currently not used and will probably go away soon.
  attr_reader :line_number

  class << self
    # First time I've done this.  I like the name so much that I
    # overloaded it.
    #
    # If called with one argument that is a Filter, then
    # local_add_filter is called.
    #
    # If called with any other signature, Item.add_filter is called if
    # the target is not Item.  If the target is Item, then
    # Item.add_filter_to_class is called.
    def add_filter(*args, &proc)
      if args.length == 1 && args[0].is_a?(Filter)
        local_add_filter(args[0])
      else
        if self == Item
          add_filter_to_class(args[0], args[1], &proc)
        else
          Item.add_filter(*args, &proc)
        end
      end
    end

    # Returns the list of filters for this class and all of its super
    # classes that support the call.  Thus if Ethchan is a subclass of
    # Device and Device is a subclass of Item, calling Ethchan.filters
    # results in the filters for Ethchan followed by the filters for
    # Device, followed by the filters for Item.
    def filters
      temp = []
      entity = self
      while entity
        temp << entity.local_filters if entity.respond_to?(:local_filters)
        entity = entity.superclass
      end
      temp.flatten
    end

    # The set of filters only for this class sorted using Filter#<=>
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
    # marshaled snap file can be reloaded.  See Snapper#restore for
    # more info
    def inherited(subclass)
      children.push(subclass.to_s)
      Item.load_filters(subclass)
    end

    # Called via Item.inherited to load the filters for the new class
    # when it is created.
    def load_filters(klass)
      if self == Item
        class_hash[klass.to_s].each { |filter| klass.add_filter(filter) }
      else
        Item.load_filters(klass)
      end
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
    def add_filter_to_class(klass, options = {}, &proc)
      klass = klass.to_s
      filter = Filter.new(options, &proc)
      if (::Object.const_defined?(klass) &&
          (klass = ::Object.const_get(klass)) &&
          klass.respond_to?(:add_filter))
        klass.add_filter(filter)
      else
        class_hash[klass] << filter
      end
    end

    # Each class has its own set of filters.  This method adds Filter
    # to the class that is the target of the message.
    # e.g. Foo.add_filter(filter) will add the Filter to class Foo.
    def local_add_filter(filter)
      local_filters << filter
    end

    # The local hash used by add_filter_to_class and load_filters.
    def class_hash
      @class_hash ||= Hash.new { |hash, key| hash[key] = [] }
    end
  end

  # In concept, prints the item.  In reality, it finds the first
  # filter from #filters that is valid for context#level and then
  # calls that filter's Filter#run method.  Sets #printed to true
  # after the filter is run.  Sets internal #printing to true while
  # filter is running and thens it back to false when it completes.
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

  # A convenience method.  With no context, it calls Item.filters.
  # With a context, it selects the result of Item.filters with
  # Filter#level === Context#level
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
  # call: device.subclass(Sea) creates a new instance of Sea moving
  # all of the data from device into the new instance.
  def subclass(klass)
    # The @hash.dup is key or we create a loop and we can't produce json
    new_item = klass.new(@text, @hash.dup, @orig_key, @line_number, @db)
    new_item[:super] = self.dup
    new_item
  end

  # The original text of the entry
  # The database that the item will be part of as db
  # hash, orig_key, and line_number are present just to get the magic
  # needed for #subclass and missing_method to work.
  def initialize(text = "", hash = {}, orig_key = {}, line_number = {}, db)
    @text = text
    @hash = hash
    @orig_key = orig_key
    @line_number = line_number
    @db = db
    @printed = false
    @printing = false
  end

  # Returns if entity has been printed
  def printed
    @printed
  end

  # if the text representation is being built up line by line then use
  # this entry.
  def <<(line)
    @text << line
    self
  end

  # to return the original text that was parsed for this item.
  def to_text
    @text
  end

  # optional parse method used by some subclasses.  It should always
  # return self when done.
  def parse
    self
  end

  # Part of the method_missing magic.  Returns true if the method
  # matches a key in the hash or if Hash responds to the method.
  def respond_to_missing?(method, include_all)
    find_name(method) || @hash.respond_to?(method, include_all)
  end

  # Two magic things happen in here.  The first is a hash key can be
  # accessed as if it was a getter so <tt>item['dog']</tt> can be
  # accessed as <tt>item.dog</tt>.  The other piece of magic is if a
  # method that Hash responds to is called, then that method is sent
  # to the @hash instance variable.  If the result is a new hash, then
  # a new Item (of the same class as the original) is returned with
  # the original orig_key, line_numbers, text, and db but with the
  # new hash.  If the result is the same hash, then the method must
  # have modified the existing hash and self is returned.  Last, if
  # the method returns a different value (like +length+), then that
  # value is returned.
  def method_missing(method, *args, &proc)
    if !block_given? && args.length == 0 && @hash.has_key?(method)
      return @hash[method]
    end

    # The default is the send the message to @hash.  If the method
    # returns a hash, we check to see if it is the original hash.  If
    # it is, we return (the modified) self.  If it is not, we create a
    # new Item with the appropriate elements.  Last, if the result is
    # not a hash (e.g. length), we just return the result.
    orig_hash_id = @hash.object_id
    if @hash.respond_to?(method)
      result = @hash.send(method, *args, &proc)
      if result.class == Hash
        if result.object_id == orig_hash_id
          self
        else
          self.class.new(@text, result, @orig_key, @line_number, @db)
        end
      else
        result
      end
    else
      super
    end
  end

  # In simple terms, sends the message to the hash instance variable
  # but first, key is modified by fix_key.  Also, if this call is
  # going to create a new field within the hash, the original key is
  # saved off in orig_key.  If there is already an existing value,
  # then the key is compared to the value in orig_key and if they
  # differ, an exception is thrown.
  def []=(key, value)
    fixed_key = fix_key(key)
    if @hash.has_key?(fixed_key) && 
       unless key == @orig_key[fixed_key] || key.is_a?(Symbol)
         fail "Collision of new key #{key.inspect} with previous key #{@orig_key[fixed_key].inspect}"
       end
    else
      @orig_key[fixed_key] = key
      @line_number[fixed_key] = @text.respond_to?(:lineno) ? @text.lineno : nil
    end
    @hash[fixed_key] = value
  end

  # Checks to see if <tt>fix_key(key)</tt> is a key of the hash.
  def key?(key)
    @hash[fix_key(key)]
  end

  # same as #key?
  def has_key?(key)
    @hash.has_key?(fix_key(key))
  end

  # Returns the value at <tt>fix_key(key)</tt>
  def [](key)
    @hash[fix_key(key)]
  end

  # An enumerator that produces a flat set of values.  Each value is a
  # two element array.  The first element is the original keys, separated by
  # commas, to reach the value.  The second element is the value.  All
  # values will be simple Fixnums or Strings
  def flat_keys(nesting = [])
    flatten_keys(self, nesting)
  end

  def to_json(options = {})
    temp = @hash.dup
    temp[:text] = @text
    temp[:orig_key] = @orig_key
    temp.to_json(options)
  end

  private

  # The magic behind flat_keys: a lazy recursive enumerator.  thing
  # may be an Item, List, WriteOnceHash, or a simple value
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
  def fix_key(key)
    key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
  end

  # not sure why but returns method if has_key? returns true and nil
  # otherwise.  Used by respond_to_missing?
  def find_name(method)
    @hash.has_key?(method) && method
  end
end
