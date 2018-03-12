require_relative "print"

# Note that this file is copied over to doc/filters and munged so we
# can get it into the documentation.  The startdoc below clues the
# copy of where to start
# :startdoc:

Print.add_filter("Alert", { level: 1 .. 10 }) do |context, item|
  context.output(item.to_text, [ :red ])
end

# Print the CEC out which prints out the info about the CEC along with
# the list of {Alert}s and {LPAR}s nested one level deeper.
Print.add_filter("CEC", { level: 0 .. 11 }) do |context, cec|
  if context.level >= 2
    context.output("CEC model:#{cec.model} CPU:#{cec.cpu_type} " +
                   "firmware:#{cec.firmware_level} Id:#{cec.id_to_system}")
  end
  cec.alerts.print(context.nest)
  cec.lpar_list.print(context.nest)
  context
end

# Ethernet filter for all levels calls output for the currenct device
# as well as the error log entries from errpt.out, the entstat -d
# output from tcpip.snap, and the lsattr output from general.snap
Print.add_filter("Ethernet", { level: 0 .. 11 }) do |context, item|
  unless item.printed
    if context.level >= 2
      temp = item.description(context)
      if item.cu_dv.status == 1
        context.output(temp)
      else
        context.output(temp, [ :nocr ])
        context.output("Defined", [ :red ])
      end
    end
    item['errpt'].print(context.nest) if item['errpt']
    item['entstat'].print(context.nest) if item['entstat']
    item['lsattr'].print(context.nest) if item['lsattr']
  end
end

# The level 3 through 7 Entstat filter prints out lines that contain
# error, overrun, or underrun if the values are not zero.  It also
# checks the LACP Actor and Partner State to make sure that the state
# is good.
IGNORE_ITEMS = /Side Statistics,Packets dropped/
TRANSMIT_REGEXP = /transmit/i
RECEIVE_REGEXP = /receive/i
SEA_QUEUE_REGEXP = /Queue full dropped packets/

Print.add_filter("Entstat", { level: 3 .. 7 }) do |context, item|
  item.flat_keys.each do |k, v|
    tx = item.transmit_statistics['Packets']
    rx = item.receive_statistics['Packets']
    if /error|overrun|underrun|dropped|drops/i.match(k) && v != 0
      # This is more noise than useful
      next if IGNORE_ITEMS.match(k)
      extra = ""
      if (t = TRANSMIT_REGEXP.match(k)) || (r = RECEIVE_REGEXP.match(k))
        per = (100.0 * v / (t ? tx : rx))
        extra = " %5.2f%%" % per
      end
      if SEA_QUEUE_REGEXP.match(k)
        items = item.find_path(k)
        queue = items[-2]
        packets = queue['Queue packets count']
        per = (100.0 * v / packets )
        extra = " %5.2f%%" % per
      end
      context.output("#{k}:#{v}#{extra}")
    end
  end
  # Report bad LACP
  [ 'Actor State', 'Partner State' ].each do |key|
    if h = item[key]
      bad_values = []
      [ ['Aggregation', 'Aggregatable'],
        ['Synchronization', 'IN_SYNC'],
        ['Collecting', 'Enabled'],
        ['Distributing', 'Enabled'],
        ['Defaulted', 'False'],
        ['Expired', 'False'] ].each do |k, v|
        bad_values.push("#{k}=#{h[k]}") if h[k] != v
      end
      context.output("Bad LACP on #{key}:#{bad_values.join(',')}") unless bad_values.empty?
    end
  end
end

# The level 8 through 10 filter for Entstat simply dumps the text to
# output.  This probably needs to be improved.
Print.add_filter("Entstat", { level: 8 .. 10 }) do |context, item|
  text = item.to_text.each_line
  text = text.select { |line| /\A=+\Z/.match(line) ? false : true }
  context.output(text)
end

# The filter for EntstatVioent levels 3 through 7 print out the VLAN
# Tag ID (PVID) as well as the allowed VLANs.  It also checks and
# prints out any Hypervisor Send or Receive Failures that are
# non-zero.
Print.add_filter("EntstatVioent", { level: 3 .. 7 })  do |context, item|
  text = "Port VLAN ID: #{item["Port VLAN ID"]}"
  text += " VLAN Tag IDs #{item["VLAN Tag IDs"]}" unless item["VLAN Tag IDs"] == "None"
  text += " on #{item["Switch ID"]}"
  if item['Trunk Adapter'] == "True"
    text += " Active:#{item["Active"]} Pri:#{item["Priority"]}"
  end
  text = [ text ]
  unless item["Hypervisor Send Failures"] == 0
    tx = item.transmit_statistics['Packets']
    err = item["Hypervisor Send Failures"]
    per = " %5.2f%%" % (100.0 * err / tx)
    text.push("Hypervisor Send Failures: #{err}#{per}")
  end
  unless item["Hypervisor Receive Failures"] == 0
    rx = item.receive_statistics['Packets']
    err = item["Hypervisor Receive Failures"]
    per = "%5.2f%%" % (100.0 * err / rx)
    text.push("Hypervisor Receive Failures: #{err} #{per}")
  end
  context.output(text)
end

# The level 3 filter for Errpt prints out the count of errors passed
# to it.  The assumption is that the Device printing out the error
# report entries and for level 1 output, only the number of entries is
# reported (and then only if it is not zero).
# 
# This is an example of how a context can be used to just report the
# number of entries rather than the details of all the entries.
# 
Print.add_filter("Errpt", { level: 3 .. 3 }) do |context, item|
  if context.state.nil?
    context.state = { count: 0 }
    context.proc = Proc.new do |context|
      context.output("#{context.state[:count]} error log entries")
    end
  end
  context.state[:count] += 1
end

# The level 4 filter for Errpt removes duplicate error report entries
# where a duplicate is one that has the same label (and will be for
# the same device when the error log entries are printed by the Device
# filter above).
# 
# This is an example of how a context can be used to remove duplicat
# entries.
Print.add_filter("Errpt", { level: 4 .. 4 }) do |context, item|
  text = "%*s %s" % [ -22, item.label, item.date_time ]
  @internal = false

  if context.state.nil?
    context.state = {
      first: nil,
      middle_text: nil,
      last_text: nil,
      count: -1,
    }
    context.proc = Proc.new do |context|
      state = context.state
      if state[:count] > 0
        if state[:count] == 1
          context.output(state[:middle_text])
        else
          context.nest.output("#{state[:count]} duplicates removed")
        end
      end
      context.output(state[:last_text]) if state[:last_text]
      context.output() unless @internal
      state[:middle_text] = state[:last_text] = nil
      state[:count] = -1
      @internal = false
    end
  end
  state = context.state
  if state[:first] && state[:first].label == item.label
    state[:count] += 1
    state[:middle_text] = state[:last_text]
    state[:last_text] = text
  else
    if state[:last_text]
      @internal = true
      context.proc.call(context)
    end
    context.output(text)
    state[:first] = item
  end
end

# The level 5 filter prints a condensed form of the error entry but
# does not remove duplicates.
Print.add_filter("Errpt", { level: 5 .. 10 }) do |context, item|
  text = "%*s %s" % [ -22, item.label, item.date_time ]
  context.output(text)
  context.proc = Proc.new do |context|
    context.output()
  end
end

# The Ethchan filter prints out the Device entry of itself as well as
# the Device entries of the adapters listed in adapter_names as well
# as the backup_adapter.  The child entries are nested in one level.
Print.add_filter("Ethchan", { level: 0 .. 11 }) do |context, item|
  mode = "mode:" + (item.attrs[:mode] || "standard")
  item[:super].print(context.modifier(mode))
  item[:adapter_names].print(context.nest)
  if item[:backup_adapter]
    item[:backup_adapter].print(context.nest.modifier("BACKUP"))
  end
end

Print.add_filter("EthernetAdapters", { level: 0 .. 11 }) do |context, item|
  first_item = true
  item.each_value.print(context) do |context, device|
    # @todo this probably should change at higher levels to print the
    #   name and then print the status beside it.
    unless device.printed || (device.cu_dv.status == 0)
      if first_item && context.level >= 2
        context.output("Unused Adapters")
        first_item = false
      end
      device.print(context.nest)
    end
    context
  end
  if first_item && context.level >= 2
    context.output("No unused adapters")
  end
  if context.level >= 3
    context.output()
  end
end

# For all levels the Interface prints out a concise one line
# description of the interface including MTU, MAC, etc.  It also
# prints out the first IP address.  This needs to change and print out
# the entire list of IP addresses along with their netmaks.  The
# filter also prints out the Device, if any, that the interface sits
# on (loopback has no Device entry).
Print.add_filter("Interface", { level: 0 .. 11 }) do |context, item|
  unless item.printed
    if context.level >= 2
      text = item[:name]
      text += "*" if item[:down]
      indent = text.length + 1
      if ifconfig = item[:ifconfig]
        temp = ifconfig
      else
        temp = item
      end
      text += " #{temp.pretty_addr(0)}"
      # text += " #{item[:inet][0][:address]}" if item[:inet]
      # text += " #{item[:inet6][0][:address]}" if item[:inet6]
      text += " mtu:%s mac:%s ipkts:%s opkts:%s" %
              [ item[:mtu],
                item[:mac],
                item[:ipkts],
                item[:opkts] ]
      if item[:ierrs] > 0 || item[:oerrs] > 0
        context.output(text, [ :nocr ])
        text = []
        if item[:ierrs] > 0
          text << ("ierrs:%s" % item[:ierrs])
        end
        if item[:oerrs] > 0
          text << ("oerrs:%s" % item[:oerrs])
        end
        context.output(text, [ :red ])
      else
        context.output(text)
      end
      ( 1 .. (temp[:addrs].length - 1)).each do |index|
        text = "#{"%*s" % [ indent, ' ' ]}#{temp.pretty_addr(index)}"
        context.output(text)
      end
    end
    if item[:adapter]
      item[:adapter].print(context.nest)
    end
    if context.level > 2
      context.output()
    end
  end
end

# A Filter that simply runs through the list of interfaces printing
# each out.
Print.add_filter("Interfaces", { level: 0 .. 11 }) do |context, item|
  item.each_value.print(context.dup)
end

# The default Filter at level does nothing.
Print.add_filter("Item", { level: 0 }) { |context, item| } # do nothing

# The default Filter for levels 6 though 10 dumps out the text
# associated with the item.
Print.add_filter("Item", { level: 6 .. 10 }) do |context, item|
  unless item.printed
    context.output(item.to_text.split("\n"))
  end
end

# The default Filter for level 11 is to dump out all of the
# flatten_keys and their associated values.
Print.add_filter("Item", { level: 11 }) do |context, item|
  item.flat_keys.each do |key, value|
    context.output("#{key}:#{value}")
  end
end

# Print the LPAR out which prints out the info about the LPAR along
# with the list of {Alert}s and the list of {Snap}s nested one level
# deeper.
Print.add_filter("LPAR", { level: 0 .. 11 }) do |context, lpar|
  hostname = lpar.hostname
  cpus = lpar.cpus
  smt =  lpar.smt
  type = lpar.type
  entitlement = lpar.entitlement
  context.output("Host:#{hostname} Virtual CPUs:#{cpus} #{type} SMT:#{smt} Entitlement:#{entitlement}") if context.level >= 2
  lpar.alerts.print(context.nest)
  lpar.snap_list.print(context.nest)
  context
end

# Currently, the lsattr entries dump out their original text at level
# 9 through 10.  This needs to be improved and probably some level
# should print entries only if they differ from their defaults.  Also,
# the Device filter could change.  If the PdAt entries are present, it
# would provide a better mechanism for printing out the attributes.
Print.add_filter("Lsattr", { level: 0 .. 8 }) do |context, item|
end

Print.add_filter("Lsattr", { level: 9 .. 10 }) do |context, item|
  context.output(item.to_text.split("\n"))
end

# The Sea filter for all levels print out the Device entry for itself
# as well as the Device entries for the real adapter, the list of
# virtual adapters, and the control channel.
Print.add_filter("Sea", { level: 0 .. 11 }) do |context, item|
  sea_ent = item[:super]
  modifier = "ha_mode:#{sea_ent.attrs[:ha_mode]}"
  if (sea_ent.attrs[:ha_mode] != "disabled" &&
      (entstat = item.super.entstat))
    bridge_mode = entstat['Bridge Mode']
    state = entstat['State']
    modifier += " State:#{state} Bridge Mode:#{bridge_mode} Id:#{item[:vswitch_pvid]}"
  end
  sea_ent.print(context.modifier(modifier))
  item[:real_adapter].print(context.nest)
  item[:virt_adapters].print(context.nest)
  if item[:ctl_chan]
    item[:ctl_chan].print(context.nest.modifier("ctrl channel"))
  end
end

# The list of Sea entries which have not already been printed are
# printed out.
Print.add_filter("Seas", { level: 0 .. 11 }) do |context, item|
  item.each_value.print(context) do |context, device|
    unless device.printed
      context = device.print(context)
      if context.level >= 3
        context.output()
      end
    end
    context
  end
end

# Print the Snap out which prints out the info about the Snap along
# with the list of {Alert}s and the list of {Item}s the were added via
# {Snap#add_item add_item} nested one level deeper.
Print.add_filter("Snap", { level: 0 .. 11 }) do |context, snap|
  time = snap.date_time.strftime("%D %T")
  base = snap.dir.basename
  vios = snap.vios
  sp = snap.service_pack
  sp = " level:#{sp}" unless sp.empty?
  vios = " VIOS:#{vios}" unless vios.empty?
  text = "Snap dir:#{base} time:#{time}#{sp}#{vios}"
  context.output(text) if context.level >= 2
  snap.alerts.print(context.nest)
  snap.print_list.print(context.nest)
  context
end

Print.add_filter("Vlan", { level: 0 .. 11 }) do |context, item|
  modifier = "VLAN ID: #{item.attrs[:vlan_tag_id]}"
  if item[:base_adapter].printed
    modifier += " (on #{item[:base_adapter].name})"
  end
  item[:super].print(context.modifier(modifier))
  item[:base_adapter].print(context.nest)
end
