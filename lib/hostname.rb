require_relative 'devices'
require_relative 'logging'

class Hostname < Item
  def self.create(snap)
    db = snap.db
    hostname = db.create_item("Hostname")
    hostname['Node Name'] = db.lparstat_out.node_name
    hostname['Partition Name'] = db.lparstat_out.partition_name
    hostname['id_to_partition'] = db.devices.sys0.attributes.id_to_partition.value
    hostname['id_to_system'] = db.devices.sys0.attributes.id_to_system.value
    snap.print_list.add(hostname, 5)
  end

  Snapper.add_klass(self)

  def print(context)
    if context.options.level > 2
      output(context, "#" * 80)
      output(context, "##{node_name.center(78)}#")
      output(context, "#" * 80)
    elsif context.options.level >= 0
      output(context, "Host: #{node_name}")
    end
    context
  end
end
