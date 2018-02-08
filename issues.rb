# This file is automatically produced by tools/create_issues.rb
# array of issues.  each issue is an array:
# [ injecting defect, resolving defect, text ]
class BrokenFilesets

@issues = [
  [ "true", "981653", "shientdd has TX_ERR", Proc.new { |snap| dev_with(snap, 'pci/shientdd') } ],
  [ "true", "983358", "musentdd receive path hangs on certain size pkt", Proc.new { |snap| dev_with(snap, 'pci/musentdd') } ],
  [ "true", "995427", "mlxentdd queue can hang", Proc.new { |snap| dev_with(snap, 'pci/mlxentdd') } ],
  [ "true", "1014823", "musentdd with IBM i on P8", Proc.new { |snap| dev_with(snap, 'pci/musentdd') } ],
  [ "true", "1025469", "Small MSS and small packets stall lncentdd", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "true", "1026092", "kxentdd with IBM i on P8 fails", Proc.new { |snap| dev_with(snap, 'pci/kxentdd') } ],
  [ "true", "1029399", "Small MSS and small packets stall lncentdd", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "true", "1029409", "Small MSS and small packets stall lnc2entdd", Proc.new { |snap| dev_with(snap, 'pci/lnc2entdd') } ],
  [ "true", "1029527", "Small MSS and small packets stall lncentdd", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "904189", "988438", "SYN packets get lost", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "904189", "988986", "Reset packets cause crash or adapter failures", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "904189", "996041", "Slow transfers when checksum offload does not match", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "904189", "1008972", "Large send packets from vioent cause crashes or adapter failures", Proc.new { |snap| dev_with(snap, 'vioentdd') } ],
  [ "987595", "1021773", "VLAN padding issue", Proc.new { |snap| dev_with(snap, 'vlandd') } ],
  [ "993580", "1029041", "Health Check issues", Proc.new { |snap| dev_with(snap, 'seadd') } ],
  [ "1002147", "1022163", "lncentdd will drop tagged large send packets", Proc.new { |snap| dev_with(snap, 'pci/lncentdd') } ],
  [ "1004969", "1026365", "Ether Channel weakness with Collecting", Proc.new { |snap| dev_with(snap, 'ethchandd') } ],
  [ "1015199", "1035817", "NIB Etherchannel broken", Proc.new { |snap| dev_with(snap, 'ethchandd') } ],
  [ "1029399", "1044315", "Small checksum offload packets sent via sea have invalid tcp sum", Proc.new { |snap| sea_with_entcore(snap) } ]
]

# Hash that maps a defect to a list of APARs
@defect2apars = {
  "981653" => [ "IV83072", "IV83077", "IV83083", "IV83197", "IV93694" ],
  "983358" => [ "IV80569", "IV80890", "IV81357", "IV81428", "IV81459", "IV82421", "IV84184" ],
  "995427" => [ "IV85259", "IV85321", "IV85335", "IV88113" ],
  "1014823" => [ "IV92497", "IV93655", "IV93658", "IV94015", "IV94017", "IV94039", "IV94041" ],
  "1025469" => [ "IV96881", "IV96913", "IV97011", "IV99726" ],
  "1026092" => [ "IJ01411", "IV97020", "IV97994", "IV98004", "IV98074" ],
  "1029399" => [ "IV85631", "IV85859", "IV97462", "IV97463", "IV98413", "IV99160" ],
  "1029409" => [ "IV85631", "IV85859", "IV86172", "IV97462", "IV97463" ],
  "1029527" => [ "IV85859", "IV89961", "IV98413", "IV99160", "IV99493" ],
  "904189" => [ "IV55546", "IV55679" ],
  "988438" => [ "IV82596", "IV84986", "IV85056", "IV88145", "IV88578" ],
  "988986" => [ "IV82694", "IV86856", "IV86941", "IV86960", "IV87017", "IV87162", "IV87165" ],
  "996041" => [ "IV84704", "IV86463", "IV86510", "IV86542", "IV86642", "IV88187", "IV88586" ],
  "1008972" => [ "IV90168", "IV91190", "IV91200", "IV91909", "IV92012", "IV92662" ],
  "987595" => [ "IV82161", "IV85891", "IV85990", "IV86084", "IV88144", "IV88344", "IV88576" ],
  "1021773" => [ "IV96462", "IV97735", "IV97736", "IV98814", "IV98836", "IV99135" ],
  "993580" => [ "IV84545" ],
  "1029041" => [ "IV97991", "NO_APAR" ],
  "1002147" => [ "IV89618", "IV89633", "IV89705", "IV91919", "IV92030", "IV92622", "IV92664" ],
  "1022163" => [ "IV95372", "IV95517", "IV95637" ],
  "1004969" => [ "IV88913", "IV91459", "IV91904", "IV92002", "IV92037", "IV95904" ],
  "1026365" => [ "IV95904", "IV97135", "IV97586", "IV97587", "IV97588", "IV97589", "IV97590" ],
  "1015199" => [ "IV85631" ],
  "1035817" => [ "IJ01237", "IJ01263" ],
  "1044315" => [ ]
}

end
