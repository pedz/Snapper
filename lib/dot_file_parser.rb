
# Snap has a lot of files that is a concatenation of a sequence of
# various commands with the output separated by a sequence that looks
# like ...\n ... command\n  ...\n.  This file "parses" those files.
# An example of one of these is the tcpip.snap file.
class DotFileParser

  # Base from which "dot file" types start from
  class Base
    attr_reader :text

    def initialize(text)
      @text = text
    end

    def to_json(options = {})
      @text.to_json(options)
    end
  end

  # Pattern that matches the separations between the commands
  DotSeparator = Regexp.new("\n\\.+\n\\.+ +(.+)\n\\.+\n")
  
  # Parse a "dot file".  io is the file to parse while db is the
  # "database" to add the entries to.
  def self.parse(io, db)
    pieces = io.read.split(DotSeparator)
    not_used = pieces.shift     # date or blanks before 1st command
    while true
      name, text = pieces.shift(2)
      break if name.nil?
      db.add(create_object(name, text))
    end
  end

  # Creates an object of type name passing its new method text.
  def self.create_object(name, text)
    klass_name = name.gsub(/ /, '').gsub(%r{[^a-zA-Z0-9]},'_').capitalize
    return if klass_name == ''
    unless ::Object.const_defined?(klass_name)
      ::Object.const_set(klass_name, Class.new(DotFileParser::Base))
    end
    o = ::Object.const_get(klass_name).new(text)
  end
end

require_relative 'dot_file/netstat_v'
