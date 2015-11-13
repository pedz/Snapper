require_relative 'logging'
require_relative "hash_mixins"
require 'json'

# The base type for all things in the database.
class Item
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level used by the Item class

  attr_reader :orig_key, :line_number

  def self.inherited(subclass)
    children.push(subclass.to_s)
  end

  def self.children
    @children ||= []
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
          self.class.new(@io, result, @orig_key, @line_number, @db)
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
    if @hash.has_key?(fixed_key)
      unless key == @orig_key[fixed_key] || key.is_a?(Symbol)
        fail "Collision of new key #{key.inspect} with previous key #{@orig_key[fixed_key].inspect}"
      end
    else
      @orig_key[fixed_key] = key
      @line_number[fixed_key] = @io.respond_to?(:lineno) ? @io.lineno : nil
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

  def output(context, string = "")
    @printed = true
    puts sprintf("%*s%s", context.indent*2, "", string) if context.options.level >= 0
  end

  def fix_key(key)
    key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
  end

  def find_name(method)
    @hash.has_key?(method) && method
  end
end
