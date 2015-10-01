require_relative 'logging'

# Snap has a lot of files that is a concatenation of a sequence of
# various commands with the output separated by a sequence that looks
# like
#     ...
#     ... command
#     ...
# This file "parses" those files.
# An example of one of these is the tcpip.snap file.
class DotFileParser
  include Logging
  # The log level that DotFileParser uses.
  LOG_LEVEL = Logger::INFO

  # Base from which "dot file" types start from.  If DotFileParser can
  # not find a suitable class for a particular section of a dot file,
  # it will use this as the base of a newly created class of the
  # proper name.
  class Base
    include Logging
    # The log level that DotFileParser::Base will use.
    LOG_LEVEL = Logger::INFO

    # text is generally not used but is set to the original text
    # passed to the parser.
    attr_reader :text

    # result is whatever the result of the parse produces.  This is
    # passed to_json in the Base class.
    attr_reader :result

    # Passed in the text as a string from DotFileParser::parse
    # method.  In real classes, this would parse the text in the
    # specific way that is needed for that section of the file.
    # Note that this is a string.  An IO object is passed in to
    # DotFileParser.parse.
    def initialize(text)
      @text = text
      @result = text
    end

    def to_text
      @text
    end

    def to_hash
      @result.to_hash
    end

    # Returns the resulting parsed text as a json object.  In the
    # default case, the text is simply stored and this routine returns
    # the text as a json object.
    def to_json(options = {})
      @result.to_json(options)
    end
  end

  # Pattern that matches the separations between the commands.  Note
  # that the command used to produce the file is in a subgroup.
  DotSeparator = Regexp.new("\n\\.+\n\\.+ +(.+)\n\\.+\n\n")
  
  # Parse a "dot file".  io is the file to parse and must respond to
  # read with an array while db is the "database" to add the entries
  # to.  The piece of the file before the first separator is thrown
  # away.
  def self.parse(io, db)
    # Since DotSeparator has a group within it, this results in an
    # array
    #     [ [ lines0 ], command1, [ lines1 ], command2 [ lines2 ],
    #     ... ]
    # The lines0 piece is thrown away.
    pieces = io.read.split(DotSeparator)
    not_used = pieces.shift     # date or blanks before 1st command
    while true
      name, text = pieces.shift(2)
      break if name.nil?
      db.add(create_object(name, text))
    end
  end

  # Creates an object of type derived from name passing its new method
  # text.  The name of the class derived from name is to remove all
  # the spaces, then replace all non-alphanumeric characters with
  # underscores, then capitalize the result.  e.g. netstat -v becomes
  # Netstat_v
  def self.create_object(name, text)
    klass_name = name.gsub(/ /, '').gsub(%r{[^a-zA-Z0-9]},'_').capitalize
    return if klass_name == ''
    unless ::Object.const_defined?(klass_name)
      ::Object.const_set(klass_name, Class.new(DotFileParser::Base))
    end
    o = ::Object.const_get(klass_name).new(text)
    return o
  end
end
