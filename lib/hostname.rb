require_relative 'devices'
require_relative 'logging'

class Hostname < Item
  def self.create(snap)
    db = snap.db
    hostname = Hostname.new(db)
    hostname['Node Name'] = db.lparstat_out.node_name
    hostname['Partition Name'] = db.lparstat_out.partition_name
    hostname['id_to_partition'] = db.devices.sys0.attributes.id_to_partition.value
    hostname['id_to_system'] = db.devices.sys0.attributes.id_to_system.value
    db.add(hostname)
    snap.print_list.add(hostname, 5)
  end

  Snapper.add_klass(self)

  def print(options, indent = 0, prefix = "")
    if options.level > 2
      puts "#" * 80
      puts "##{node_name.center(78)}#"
      puts "#" * 80
    elsif options.level >= 0
      puts "Host: #{node_name}"
    end
  end
end
