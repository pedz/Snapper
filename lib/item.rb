require_relative 'logging'
require 'json'

# The base type for all things in the database.
class Item < Hash
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level used by the Item class

  ##
  # The original text of the entry
  # The database that the item will be part of as db
  def initialize(text = "", db)
    super()
    @text, @db = text, db
  end

  ##
  # if the text representation is being built up line by line then use
  # this entry.
  def <<(line)
    @text << line
    self
  end

  ##
  # This is getting more complex than I wanted... but we have a need
  # to set a key of "Class" which is modified to be a method of :class
  # but that already exists.  In that case, we prefix it with _ and
  # define a method :_class.  We do this only for the instance methods
  # defined on Item at load time.
  DEFAULT_METHODS = self.instance_methods

  ##
  # Assigns value to the key in the hash but also creates a method for
  # key to simplify tests, etc.  The method's name is the same as the
  # key except it is downcased and any non-alphanumerics are changed
  # to underscores.  If the method collides with a pre-existing
  # method, an underscore is added to it.
  def []=(key, value)
    method = key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
    if DEFAULT_METHODS.include?(method)
      method = ("_" + key.to_s.downcase.gsub(/[^a-z0-9_]/, '_')).to_sym
    end
    if self.respond_to?(method)
      fail "Collision with #{key} to #{method}" unless self.key?(key)
    else
      define_singleton_method(method) { self[key] }
    end
    super
  end

  ##
  # to return the original text that was parsed for this item.
  def to_text
    @text
  end

  ##
  # optional parse method
  def parse
    self
  end
end
