require_relative 'devices'
require_relative 'logging'
require_relative 'snapper'

# An Item that contains these fields:
# [Node Name]       - The Node Name as gathered from lparstat.out
# [Partition Name]  - The Partion Name also from lparstat.out
# [id_to_partition] - The id_to_partition attribute groked from sys0
#                     attributes.
# [id_to_system]    - The id_to_system also from sys0 attributes.
#
# This is the simplest example of a snap processor (stage 2)
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

  Snapper.add_snap_processor(self)
end
