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
end
