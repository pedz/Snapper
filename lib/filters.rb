require_relative "filter"

# Note that this file is copied over to doc/filters and munged so we
# can get it into the documentation.  The startdoc below clues the
# copy of where to start
# @param  remove me
# :startdoc:

Item.add_filter("Alert", { level: 1 .. 10 }) do |context, item|
  context.output(item.to_text, [ :red ])
end

# Device filter for all levels calls output for the currenct device as
# well as the error log entries from errpt.out, the entstat -d output
# from tcpip.snap, and the lsattr output from general.snap
Item.add_filter("Device", { level: 0 .. 11 }) do |context, item|
  unless item.printed
    context.output([ item.cu_dv.name, item.cu_dv.ddins, context.modifier ].join(' '))
    item['errpt'].print(context.nest) if item['errpt']
    item['entstat'].print(context.nest)    if item['entstat']
    item['lsattr'].print(context.nest)     if item['lsattr']
  end
end

# The level 1 Entstat filter prints out lines that contain error,
# overrun, or underrun if the values are not zero.  It also checks the
# LACP Actor and Partner State to make sure that the state is good.
Item.add_filter("Entstat", { level: 1 .. 5 }) do |context, item|
  item.flat_keys.each do |k, v|
    if /error|overrun|underrun/i.match(k) && v != 0
      context.output("#{k}:#{v}")
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

# The level 2 through 10 filter for Entstat simply dumps the text to
# output.  This probably needs to be improved.  Perhaps the above
# filter's range could be 1 .. 4 and this filter could be 5 .. 10.
Item.add_filter("Entstat", { level: 6 .. 10 }) do |context, item|
  text = item.to_text.each_line
  text = text.select { |line| /\A=+\Z/.match(line) ? false : true }
  context.output(text)
end

# The filter for EntstatVioent levels 1 through 5 print out the VLAN
# Tag ID (PVID) as well as the allowed VLANs.  It also checks and
# prints out any Hypervisor Send or Receive Failures that are
# non-zero.
Item.add_filter("EntstatVioent", { level: 1 .. 5 })  do |context, item|
  text = "Port VLAN ID: #{item["Port VLAN ID"]}"
  text += " VLAN Tag IDs #{item["VLAN Tag IDs"]}" unless item["VLAN Tag IDs"] == "None"
  text += " on #{item["Switch ID"]}"
  if item['Trunk Adapter'] == "True"
    text += " Active:#{item["Active"]} Pri:#{item["Priority"]}"
  end
  text = [ text ]
  unless item["Hypervisor Send Failures"] == 0
    text.push("Hypervisor Send Failures: #{item["Hypervisor Send Failures"]}")
  end
  unless item["Hypervisor Receive Failures"] == 0
    text.push("Hypervisor Receive Failures: #{item["Hypervisor Receive Failures"]}")
  end
  context.output(text)
end

# The level 1 filter for Errpt prints out the count of errors passed
# to it.  The assumption is that the Device printing out the error
# report entries and for level 1 output, only the number of entries is
# reported (and then only if it is not zero).
# 
# This is an example of how a context can be used to just report the
# number of entries rather than the details of all the entries.
# 
Item.add_filter("Errpt", { level: 1 .. 1 }) do |context, item|
  if context.state.nil?
    context.state = { count: 0 }
    context.proc = Proc.new do |context|
      context.output("#{context.state[:count]} error log entries")
    end
  end
  context.state[:count] += 1
end

# The level 2 through 5 filter for Errpt removes duplicate error
# report entries where a duplicate is one that has the same label (and
# will be for the same device when the error log entries are printed
# by the Device filter above).
# 
# This is an example of how a context can be used to remove duplicat
# entries.
Item.add_filter("Errpt", { level: 2 .. 5 }) do |context, item|
  text = "%*s %s" % [ -22, item.label, item.date_time ]

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
      context.output(state[:last_text])
      state[:middle_text] = state[:last_text] = nil
      state[:count] = -1
    end
  end
  state = context.state
  if state[:first] && state[:first].label == item.label
    state[:count] += 1
    state[:middle_text] = state[:last_text]
    state[:last_text] = text
  else
    if state[:last_text]
      context.proc.call(context)
    end
    context.output(text)
    state[:first] = item
  end
end

# The Ethchan filter prints out the Device entry of itself as well as
# the Device entries of the adapters listed in adapter_names as well
# as the backup_adapter.  The child entries are nested in one level.
Item.add_filter("Ethchan", { level: 0 .. 11 }) do |context, item|
  item[:super].print(context)
  item[:adapter_names].print(context.nest)
  if item[:backup_adapter]
    item[:backup_adapter].print(context.nest.modifier("BACKUP"))
  end
end

Item.add_filter("EthernetAdapters", { level: 0 .. 11 }) do |context, item|
  first_item = true
  item.each_value.print(context) do |context, device|
    # @todo this probably should change at higher levels to print the
    #   name and then print the status beside it.
    unless device.printed || (device.cu_dv.status == 0)
      if first_item
        context.output("Unused Adapters")
        first_item = false
      end
      device.print(context.nest)
    end
    context
  end
  if first_item
    context.output("No unused adapters")
  end
  if context.level > 0
    context.output()
  end
end

# This could be broken into two filters possibly.  For levels greater
# than 2, a banner is printed with the host name centered.  For level
# 0 and 1, a simpler "Host: foo" is printed.
Item.add_filter("Hostname", { level: 0 .. 10 }) do |context, item|
  if context.level > 2
    context.output("#" * 80)
    context.output("##{item.node_name.center(78)}#")
    context.output("#" * 80)
  elsif context.level >= 0
    context.output("Host: #{item.node_name}")
  end
end

# For all levels the Interface prints out a concise one line
# description of the interface including MTU, MAC, etc.  It also
# prints out the first IP address.  This needs to change and print out
# the entire list of IP addresses along with their netmaks.  The
# filter also prints out the Device, if any, that the interface sits
# on (loopback has no Device entry).
Item.add_filter("Interface", { level: 0 .. 11 }) do |context, item|
  unless item.printed
    text = item[:name]
    text += " #{item[:inet][0][:address]}" if item[:inet]
    text += " #{item[:inet6][0][:address]}" if item[:inet6]
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
    if item[:adapter]
      item[:adapter].print(context.nest)
    end
    if context.level > 0
      context.output()
    end
  end
end

# A Filter that simply runs through the list of interfaces printing
# each out.
Item.add_filter("Interfaces", { level: 0 .. 11 }) do |context, item|
  if context.level > 2
    context.output("##{"Interfaces".center(78)}#")
  end
  item.each_value.print(context.dup)
end

# The default Filter at level does nothing.
Item.add_filter("Item", { level: 0 }) { |context, item| } # do nothing

# The default Filter for levels 6 though 10 dumps out the text
# associated with the item.
Item.add_filter("Item", { level: 6 .. 10 }) do |context, item| # print all the text
  unless item.printed
    context.output(item.to_text)
  end
end

# The default Filter for level 11 is to dump out all of the
# flatten_keys and their associated values.
Item.add_filter("Item", { level: 11 }) do |context, item|
  item.flat_keys.each do |key, value|
    context.output("#{key}:#{value}")
  end
end

# Currently, the lsattr entries dump out their original text at level
# 4 through 10.  This needs to be improved and probably some level
# should print entries only if they differ from their defaults.  Also,
# the Device filter could change.  If the PdAt entries are present, it
# would provide a better mechanism for printing out the attributes.
Item.add_filter("Lsattr", { level: 4 .. 10 }) do |context, item|
  context.output(item.to_text)
end

# The Sea filter for all levels print out the Device entry for itself
# as well as the Device entries for the real adapter, the list of
# virtual adapters, and the control channel.
# FIXME: the ability for the caller to add a suffix to the first line
# of output needs to be added so the control channel can be easily
# identified from the virtual adapters used to bridge packets.
# Likewise, the backup adapter for ethchan also needs to be marked.
Item.add_filter("Sea", { level: 0 .. 11 }) do |context, item|
  sea_ent = item[:super]
  modifier = "ha_mode:#{sea_ent.attributes.ha_mode.value}"
  if (sea_ent.attributes.ha_mode.value != "disabled" &&
      entstat = item.super.entstat)
    bridge_mode = entstat['Bridge Mode']
    state = entstat['State']
    modifier += " State:#{state} Bridge Mode:#{bridge_mode}"
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
Item.add_filter("Seas", { level: 0 .. 11 }) do |context, item|
  item.each_value.print(context) do |context, device|
    unless device.printed
      context = device.print(context)
      if context.level > 0
        context.output()
      end
    end
    context
  end
end

Item.add_filter("Vlan", { level: 1 .. 11 }) do |context, item|
  modifier = "VLAN ID: #{item.attributes.vlan_tag_id.value}"
  item[:super].print(context.modifier(modifier))
  item[:base_adapter].print(context.nest)
end
