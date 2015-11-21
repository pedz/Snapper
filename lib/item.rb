require_relative 'logging'
require 'json'

# The base type for all things in the database.
class Item
  include Logging
  LOG_LEVEL = Logger::INFO

  attr_reader :orig_key, :line_number

  class << self
    def add_filter(filter)
      local_filters << filter
    end

    def filters
      temp = []
      entity = self
      while entity
        temp << entity.local_filters if entity.respond_to?(:local_filters)
        entity = entity.superclass
      end
      temp.flatten
    end

    def local_filters
      (@filters ||= []).sort!
    end
  end

  def print(context)
    unless @printing
      @printing = true
      filters(context).first(1).each { |filter| filter.blah(context, self) }
    end
    @printing = false
    @printed = true
    context
  rescue => e
    STDERR.puts self.class
    raise e
  end

  def filters(context = nil)
    if context
      self.class.filters.select { |filter| filter.level === context.level }
    else
      self.class.filters
    end
  end

  def self.inherited(subclass)
    children.push(subclass.to_s)
  end

  def self.children
    @children ||= []
  end

  ##
  # creates an instance of subclass klass and moves all the instance
  # variables of the original Item into the new instance.  For
  # example, in Seas, when a Device is discovered to be a Sea, the
  # call: device.subclass(Sea) creates a new instance of Sea moving
  # all of the data from device into the new instance.
  def subclass(klass)
    new_item = klass.new(@text, @hash, @orig_key, @line_number, @db)
    new_item[:super] = self
    new_item
  end

  ##
  # The original text of the entry
  # The database that the item will be part of as db
  def initialize(text = "", hash = {}, orig_key = {}, line_number = {}, db)
    @text = text
    @hash = hash
    @orig_key = orig_key
    @line_number = line_number
    @db = db
    @printed = false
    @printing = false
  end

  ##
  # Returns if entity has been printed
  def printed
    @printed
  end

  ##
  # if the text representation is being built up line by line then use
  # this entry.
  def <<(line)
    @text << line
    self
  end

  ##
  # to return the original text that was parsed for this item.
  def to_text
    @text
  end

  ##
  # to return the base hash within the object (I'm not liking this
  # much)
  def to_hash
    @hash
  end

  ##
  # optional parse method
  def parse
    self
  end

  def respond_to_missing?(method, include_all)
    find_name(method) || @hash.respond_to?(method, include_all)
  end

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

  def key?(key)
    @hash[fix_key(key)]
  end

  def has_key?(key)
    @hash.has_key?(fix_key(key))
  end

  def [](key)
    @hash[fix_key(key)]
  end

  private

  def fix_key(key)
    key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
  end

  def find_name(method)
    @hash.has_key?(method) && method
  end
end
