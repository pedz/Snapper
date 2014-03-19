
Top = self.class

class Odm
  # Base from which ODM types start from
  class Base
    def initialize(arg)
      @arg = arg
    end

    def each_pair(&block)
      @arg.each_pair(&block)
    end

    def keys
      @arg.keys
    end

    def method_missing(name, *args, &block)
      n = name.to_s
      return @arg[n] if @arg.has_key?(n)
      super
    end
  end
  
  # Parses io (via each_line) into ODM objects and adds them to db
  # (via add).  The stanza type determines the type of object.  For
  # example, a stanza starting with CuAt will do CuAt.new(hash) where
  # hash is the attributes found in the ODM stanza.
  def self.parse(io, db)
    name = nil                  # name of the object class
    hash = nil                  # attributes of the new object
    full_line = nil             # the line we have so far
    io.each_line do |this_line|
      # empty line
      if this_line.match(/^\s*$/)
        next
      end

      # replace string literals e.g. "\n" with a newline
      this_line.gsub!(/\\./) { |match|
        case match
        when '\n'; "\n"
        when '\\'; "\\"
        end
      }

      # Accumulate lines
      if full_line
        full_line += this_line
      else
        full_line = this_line
      end

      # if line ends with a continuation character
      if this_line.match(/\\$/)
        full_line.chomp!        # kill line terminator
        full_line.chop!         # kill the \
        next
      end

      # Looks like a new stanza
      if md = full_line.match(/^(\w+):$/)
        # we are accumulating an object then create it
        if name
          db.add(create_object(name, hash))
        end
        # remember new object's class name and start hash off fresh
        name = md[1]
        hash = Hash.new

        # looks like an attribute
      elsif (md = full_line.match(/^\s+(\w+)\s*=\s*((.|\n)*)$/))
        hash[md[1]] = convert(md[2])
      else                      # format seems broken
        raise "Bad format"
      end
      # line has been processed
      full_line = nil
    end
    # create possible last object
    if name
      db.add(create_object(name, hash))
    end
  end

  private

  # Converts a value (right of the equals sign) read from the odm
  # files what it means.  In particular, a string is quoted with an
  # extra set of double quotes and an integer comes in as a string and
  # is converted to an integer.
  def self.convert(a)
    if md = a.match(/"((.|\n)*)"/)
      return md[1]
    end
    if a.match(/^[0-9]+$/)
      return a.to_i
    end
    raise "Can not convert #{a}"
  end

  # Creates an object of type name passing its new method hash.
  def self.create_object(name, hash)
    unless Top.const_defined?(name)
      Top.const_set(name, Class.new(Odm::Base))
    end
    o = Top.const_get(name).new(hash)
  end
end

require_relative 'odm/cuat'
require_relative 'odm/cudv'
