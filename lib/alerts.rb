require_relative 'snapper'
require_relative 'logging'

# This is a file that has snap_processors that create alerts.

class TcpAlerts
  def self.create(snap)
    db = snap.db
    snap.add_alert("tcptr_enable is not zero") if db.no_a.tcptr_enable != 0
    snap.add_alert("tcp_tcpsecure has bit 4 set") if (db.no_a.tcp_tcpsecure & 4) == 4
    # I need a sample dump so I can create an alert when IPSec is enabled.
  end

  Snapper.add_snap_processor(self)
end
