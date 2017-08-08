require_relative 'snapper'
require_relative 'logging'

# This is a file that has snap processor that create alerts.
class TcpAlerts
  # Adds an alert if tcptr_enable is not zero and if tcp_tcp_secure
  # has bit 2 set.
  # @param snap [Snap] the snap to process
  # @param options [Options] The options specified on the command line
  def self.process_snap(snap, options)
    db = snap.db
    if (no_a = db['no -a'])
      snap.add_alert("tcptr_enable is not zero") if no_a.tcptr_enable != 0
      snap.add_alert("tcp_tcpsecure value of #{no_a.tcp_tcpsecure} has bit 2 (value of 4) set") if (no_a.tcp_tcpsecure & 4) == 4
    end
  end

  Snapper.add_snap_processor(self)
end
