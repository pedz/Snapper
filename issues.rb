# This file is automatically produced by tools/create_issues.rb
# array of issues.  each issue is an array:
# [ injecting defect, resolving defect, text ]
class BrokenFilesets

@issues = [
  [ "true", "1029399", "Small MSS and small packets stall lncentdd", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "true", "1029527", "Small MSS and small packets stall lncentdd", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "904189", "988438", "SYN packets get lost", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "904189", "988986", "Reset packets cause crash or adapter failures", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "904189", "996041", "Slow transfers when checksum offload does not match", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "904189", "1008972", "Large send packets cause crash or adapter failures", Proc.new { |snap| dev_with(snap, 'vioentdd') } ],
  [ "993580", "1029041", "Health Check issues", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "1002147", "1022163", "lncentdd will drop tagged large send packets", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "1004969", "1026365", "Ether Channel weakness with Collecting", Proc.new { |snap| dev_with(snap, 'ethchandd') } ]
]

# Hash that maps a defect to a list of APARs
@defect2apars = {
  "1029399" => [ "IV85631", "IV85859", "IV97462", "IV97463", "IV98413" ],
  "1029527" => [ "IV85859", "IV98413" ],
  "904189" => [ "IV55546", "IV55679" ],
  "988438" => [ "IV82596", "IV84986", "IV85056", "IV88145", "IV88578" ],
  "988986" => [ "IV82694", "IV86856", "IV86941", "IV86960", "IV87017", "IV87162", "IV87165" ],
  "996041" => [ "IV84704", "IV86463", "IV86510", "IV86542", "IV86642", "IV88187", "IV88586" ],
  "1008972" => [ "IV90168", "IV91190", "IV91200", "IV91909", "IV92012", "IV92662" ],
  "993580" => [ "IV84545" ],
  "1029041" => [ "IV97991", "NO_APAR" ],
  "1002147" => [ "IV89618", "IV89633", "IV89705", "IV91919", "IV92030", "IV92622", "IV92664" ],
  "1022163" => [ "IV95372", "IV95517", "IV95637" ],
  "1004969" => [ "IV88913", "IV91459", "IV91904", "IV92002", "IV92037", "IV95904" ],
  "1026365" => [ "IV95904", "IV97135", "IV97586", "IV97587", "IV97588", "IV97589", "IV97590" ]
}

end
