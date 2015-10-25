require_relative "item"

class Interface < Item
  include Logging
  LOG_LEVEL = Logger::INFO

  def initialize(name, db)
    super("", db)
    self[:name] = name
  end

  def print(db_list, indent = "")
    Print.printed(self[:name])
    printf("%s%s mtu:%s mac:%s ipkts:%s ierrs:%s opkts:%s oerrs:%s\n",
           indent,
           self[:name],
           self[:mtu],
           self[:mac],
           self[:ipkts],
           self[:ierrs],
           self[:opkts],
           self[:oerrs])
    dev_name = self[:name].sub(/e[tn]/, "ent")
    obj = db_list[0]['Devices'][dev_name]
    obj.print(db_list, index + "  ")
  end
end
