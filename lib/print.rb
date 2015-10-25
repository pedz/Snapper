require_relative 'logging'

class Print
  def self.needed
    @needed ||= []
  end
  
  def self.done
    @done ||= []
  end

  def self.printed(name)
    done.push(name)
  end

  def self.need(obj)
    needed.push(obj)
  end

  # Passed an array of Db
  def self.out(db_list)
    until needed.empty?
      obj = needed.pop
      obj.print(db_list) unless done.include?(obj)
    end
  end
end
