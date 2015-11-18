require_relative "item"

class Interface < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def print(context)
    unless printed
      text = self[:name]
      text += " IPv4:#{self[:inet][0][:address]}" if self[:inet]
      text += " IPv6:#{self[:inet6][0][:address]}" if self[:inet6]
      text += " mtu:%s mac:%s ipkts:%s ierrs:%s opkts:%s oerrs:%s" %
             [ self[:mtu],
               self[:mac],
               self[:ipkts],
               self[:ierrs],
               self[:opkts],
               self[:oerrs]]
      output(context, text)
      # See if we can find the adapter and then print it out as well
      unless self[:adapter]
        if @db.devices
          device_name = self.name.sub(/e[nt]/, "ent")
          self[:adapter] = @db.devices[device_name]
        end
      end
      if self[:adapter]
        self[:adapter].print(context.nest)
      end
      if context.options.level > 0
        output(context)
      end
    end
    context
  end
end
