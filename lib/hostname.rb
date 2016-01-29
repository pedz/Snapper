require_relative 'devices'
require_relative 'logging'
require_relative 'snapper'
require_relative 'snap'

# An Item that contains these fields:
# [hostname]        The value of the hostname attribute from the
#                   inet0 device.
#
# [Node Name]       The Node Name as gathered from lparstat.out
#
# [Partition Name]  The Partion Name also from lparstat.out
#
# [id_to_partition] The id_to_partition attribute groked from sys0
#                   attributes.
#
# [id_to_system]    The id_to_system also from sys0 attributes.
#
# This is the simplest example of a snap processor.  I'm not sure
# anyone uses this any more.
class Hostname < Item
  # @param snap [Snap] The snap to process.
  def self.process_snap(snap)
    db = snap.db
    hostname = db.create_item("Hostname")
    hostname['hostname'] = db.devices.inet0.attrs.hostname
    hostname['Node Name'] = db.lparstat_out.node_name
    hostname['Partition Name'] = db.lparstat_out.partition_name
    hostname['id_to_partition'] = db.devices.sys0.attrs.id_to_partition
    hostname['id_to_system'] = db.devices.sys0.attrs.id_to_system
  end

  Snapper.add_snap_processor(self)
end
