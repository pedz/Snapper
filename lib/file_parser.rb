require_relative 'logging'
require_relative 'item'
require_relative 'db'
require 'json'

# @abstract Subclass and override the {#parse} method.
# The base type for the various parsers.  This is a virtual class in
# that its parse method must be overriden.
class FileParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # io is usually a File and path is the path the file came from.  But
  # for testing, path can be nil and io is a StringIO.  db is the
  # database.
  # @param io [IO] The file or string to parse.
  # @param db [Db] The database to populate during the parse.
  # @param path [Pathname, nil] Not set during testing.
  def initialize(io, db, path = nil)
    @io, @db, @path = io, db, path
    @history = []
    @lines = @io.each_line
    @lineno = 0
  end

  ##
  # Abstract parse method
  def parse
    fatal "Please override this method"
  end

  def next_line
    @line = @lines.next
    @line.chomp!
    @history.push(@line)
    @history.shift until @history.length < 5
    @lineno += 1
    @line
  end

  def each_line
    loop do
      next_line
      yield @line
    end
  rescue StopIteration
  rescue => e
    e = ParseError.from_exception(e, @history)
    e.add_message("at line #{@lineno}")
    raise e
  end
end
