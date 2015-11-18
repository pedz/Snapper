require_relative "filter"

Filter.add("Entstat_vioent")  { |context, item|
  text = "Port VLAN ID: #{item["Port VLAN ID"]}"
  text += " VLAN Tag IDs #{item["VLAN Tag IDs"]}" unless item["VLAN Tag IDs"] == "None"
  text
}
