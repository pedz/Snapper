
class Odm
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
      this_line.gsub(/\\./) { |match|
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
      elsif (md = full_line.match(/^\s+(\w+)\s*=\s*(.*)$/))
        hash[md[1]] = md[2]
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

  def self.create_object(name, hash)
    o = Class.const_get(name).new(hash)
  end
end
