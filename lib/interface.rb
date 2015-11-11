require_relative "item"

class Interface < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def print(options, indent = 0, prefix = "")
    unless printed
      text = "%s mtu:%s mac:%s ipkts:%s ierrs:%s opkts:%s oerrs:%s" %
             [ self[:name],
               self[:mtu],
               self[:mac],
               self[:ipkts],
               self[:ierrs],
               self[:opkts],
               self[:oerrs]]
      output(options, indent, text)
      # See if we can find the adapter and then print it out as well
      unless self[:adapter]
        if @db.devices
          device_name = self.name.sub(/e[nt]/, "ent")
          self[:adapter] = @db.devices[device_name]
        end
      end
      if self[:adapter]
        self[:adapter].print(options, indent+1, prefix)
      end
      if options.level > 0
        output(options, indent, "")
      end
    end
  end
end
