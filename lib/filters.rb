require_relative "filter"
# We need to require each class that we add a filter to or else when
# we create the class its filters will be empty.
require_relative "device"
require_relative "entstat"
require_relative "entstat_vioent"
require_relative "errpt"
require_relative "ethchan"
require_relative "ethchans"
require_relative "hostname"
require_relative "interface"
require_relative "interfaces"
require_relative "item"
require_relative "lsattr"
require_relative "sea"
require_relative "seas"

Filter.add("Device", { level: 0 .. 11 }) do |context, item|
  unless item.printed
    context.output("#{item.cudv.name} #{item.cudv.ddins}")
    item['errpt'].print_list(context.nest) if item['errpt']
    item['entstat'].print(context.nest)    if item['entstat']
    item['lsattr'].print(context.nest)     if item['lsattr']
  end
end

Filter.add("Entstat", { level: 1 }) do |context, item|
  item.flat_keys.each do |k, v|
    if /error|overrun|underrun/i.match(k) && v != 0
      context.output("#{k}:#{v}")
    end
  end
  # Report bad LACP
  [ 'Actor State', 'Partner State' ].each do |key|
    if h = item[key]
      bad_values = []
      [ ['LACP activity', 'Active'],
        ['Aggregation', 'Aggregatable'],
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

Filter.add("Entstat", { level: 2 .. 11 }) do |context, item|
  text = item.to_text.each_line
  text = text.select { |line| /\A=+\Z/.match(line) ? false : true }
  context.output(text)
end

Filter.add("Entstat_vioent", { level: 1 .. 5 })  do |context, item|
  text = "Port VLAN ID: #{item["Port VLAN ID"]}"
  text += " VLAN Tag IDs #{item["VLAN Tag IDs"]}" unless item["VLAN Tag IDs"] == "None"
  text = [ text ]
  unless item["Hypervisor Send Failures"] == 0
    text.push("Hypervisor Send Failures: #{item["Hypervisor Send Failures"]}")
  end
  unless item["Hypervisor Receive Failures"] == 0
    text.push("Hypervisor Receive Failures: #{item["Hypervisor Receive Failures"]}")
  end
  context.output(text)
end

# This is an example of how a context can be used to just report the
# number of entries rather than the details of all the entries.
Filter.add("Errpt", { level: 1 .. 1 }) do |context, item|
  if context.state.nil?
    context.state = { count: 0 }
    context.proc = Proc.new do |context|
      context.output("#{context.state[:count]} error log entries")
    end
  end
  context.state[:count] += 1
end

# This is an example of how a context can be used to remove duplicat
# entries.
Filter.add("Errpt", { level: 2 .. 5 }) do |context, item|
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

Filter.add("Ethchan", { level: 0 .. 11 }) do |context, item|
  item[:super].print(context)
  item.attributes.adapter_names.value.split(',').print_list(context.nest) do |context, adapter_name|
    item.devices[adapter_name].print(context)
  end
end

Filter.add("Hostname", { level: 0 .. 11 }) do |context, item|
  if context.level > 2
    context.output("#" * 80)
    context.output("##{item.node_name.center(78)}#")
    context.output("#" * 80)
  elsif context.level >= 0
    context.output("Host: #{item.node_name}")
  end
end

Filter.add("Interface", { level: 0 .. 11 }) do |context, item|
  unless item.printed
    text = item[:name]
    text += " IPv4:#{item[:inet][0][:address]}" if item[:inet]
    text += " IPv6:#{item[:inet6][0][:address]}" if item[:inet6]
    text += " mtu:%s mac:%s ipkts:%s ierrs:%s opkts:%s oerrs:%s" %
            [ item[:mtu],
              item[:mac],
              item[:ipkts],
              item[:ierrs],
              item[:opkts],
              item[:oerrs]]
    context.output(text)
    if item.devices
      device_name = item.name.sub(/e[nt]/, "ent")
      if adapter = item.devices[device_name]
        adapter.print(context.nest)
      end
    end
    if context.level > 0
      context.output()
    end
  end
end

Filter.add("Interfaces", { level: 0 .. 11 }) do |context, item|
  if context.level > 2
    context.output("##{"Interfaces".center(78)}#")
  end
  item.each_value.print_list(context.dup)
end

Filter.add("Ethchans", { level: 0 .. 11 }) do |context, item|
  if context.level > 2
    context.output("##{"Interfaces".center(78)}#")
  end
  item.each_value.print_list(context.dup)
end

Filter.add("Item", { level: 0 }) { |context, item| } # do nothing

Filter.add("Item", { level: 6 .. 11 }) do |context, item| # print all the text
  unless item.printed
    context.output(item.to_text)
  end
end

Filter.add("Lsattr", { level: 4 .. 11 }) do |context, item|
  context.output(item.to_text)
end

Filter.add("Sea", { level: 0 .. 11 }) do |context, item|
  item[:super].print(context)
  item.attributes.real_adapter.value.split(',').print_list(context.nest) do |context, adapter_name|
    item.devices[adapter_name].print(context)
  end
  item.attributes.virt_adapters.value.split(',').print_list(context.nest) do |context, adapter_name|
    item.devices[adapter_name].print(context)
  end
  item.attributes.ctl_chan.value.split(',').print_list(context.nest) do |context, adapter_name|
    item.devices[adapter_name].print(context)
  end
end

Filter.add("Seas", { level: 0 .. 11 }) do |context, item|
  item.each_value.print_list(context) do |context, device|
    unless device.printed
      context = device.print(context)
      if context.level > 0
        context.output()
      end
    end
    context
  end
end
