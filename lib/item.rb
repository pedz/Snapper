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
