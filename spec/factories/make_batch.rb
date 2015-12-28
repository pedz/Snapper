require 'batch'
require 'snap'
require 'date'
require 'time'
require 'hostname'

class Device < Item; end
class Sea < Device;  end

module CreateBatchDSL
  def start_new_cec(options = {})
    system_num
    @system_num += 1
    start_new_lpar(options)
  end

  def start_new_lpar(options = {})
    lpar_num
    @lpar_num += 1
    start_new_snap(options)
  end

  # The DSL has state.  In particular @db is set to the current Db
  # instance.  Thus one snap is built up, then {#new_snap} is called
  # and the next snap is built up.  This is the easiest, least verbose
  # syntax I can come up with.
  # @param options [Hash]
  # @option options [String] :dir ('some/path') The directory of the
  #   snap.
  # @option options [Object] :date_time (next in a sequence) The value
  #   to set the date_time attribute for the new Db to.
  def start_new_snap(options = {})
    new_db(options)
    dir = options[:dir] || 'some/path'
    new_sys0(options)
    inet0 = new_inet0(options)
    hostname = inet0.attributes.hostname.value
    new_lparstat_out(options.merge({ node_name: hostname, partition_name: hostname }))
    Snap.new(db: @db, dir: dir).tap do |snap|
      Hostname.process_snap(snap)
    end
  end

  def new_ent(options = {})
    new_device(options.merge({ prefix: 'ent'})).tap do |ent|
      ent['entstat'] ||= new_item
    end
  end

  def add_sea(options = {})
    ent = new_ent(options)
    options.delete(:name)
    name = ent.name

    real_adapter = options[:real_adapter] || new_ent(options)
    virt_adapters = options[:virt_adapters] || [ new_vea(options) ]
    ctl_chan = options[:ctl_chan]

    add_attr(ent, :ctl_chan, ctl_chan ? ctl_chan.name : "")
    add_attr(ent, :ha_mode, options[:ha_mode] || 'auto')
    add_attr(ent, :pvid_adapter, virt_adapters.first.name)
    add_attr(ent, :real_adapter, real_adapter.name)
    add_attr(ent, :virt_adapters, virt_adapters.map(&:name).join(','))

    sea = ent.subclass(Sea)
    sea[:ctl_chan] = ctl_chan
    sea[:pvid_adapter] = virt_adapters.first
    sea[:real_adapter] = real_adapter
    sea[:virt_adapters] = virt_adapters
    seas[name] = sea
    sea
  end

  def new_vea(options = {})
    item = new_ent(options)
    entstat = item['entstat']
    if options.has_key?(:pvid)
      entstat["Port VLAN ID"] = options[:pvid]
    else
      entstat["Port VLAN ID"] = next_vlan
    end

    if options.has_key?(:allowed)
      v = options[:allowed]
      if v.is_a?(Array) || v == "None"
        entstat["VLAN Tag IDs"] = v
      else
        v.times.inject([]) { |a| a << next_vlan }
      end
      entstat["Trunk Adapter"] = "True"
      entstat["Priority"] = 1
      entstat["Active"] = "True"
    else
      entstat["VLAN Tag IDs"] = "None"
      entstat["Trunk Adapter"] = "False"
    end

    entstat["Switch ID"] = options[:vswitch] || "ETHERNET0"

    if options[:discovery] == true
      t = entstat
      [ "Receive Information", "Receive Buffers", "Control" ].each do |attr|
        t = t[attr] = {}
      end
    end
    item
  end

  def expect_no_alerts(batch)
    expect(batch).not_to receive(:add_alert)
    batch.each_cec do |cec|
      expect(cec).not_to receive(:add_alert)
      cec.each_lpar do |lpar|
        expect(lpar).not_to receive(:add_alert)
        lpar.each_snap do |snap|
          expect(snap).not_to receive(:add_alert)
        end
      end
    end
  end

  private

  def next_vlan(count = nil)
    @vlan_number ||= 0
    if count
      count.times.inject([]) { |a| a << @vlan_number += 1 }
    else
      @vlan_number += 1
    end
  end

  def seas
    @db['seas'] || @db.create_item('seas')
  end

  def devices
    @db['Devices'] || @db.create_item('Devices')
  end

  def add_attr(item, sym, value)
    attrs = item['attributes'] ||= new_item
    attr = attrs[sym] ||= new_item
    attr['value'] = value
  end

  # Creates a new 
  def new_device(options = {})
    if options.has_key?(:name)
      name = options[:name]
    else
      prefix = options[:prefix] || "dev"
      name = "%s%d" % [ prefix, new_dev_num ]
    end
    devices[name] = new_item(Device).tap { |item| item[:name] = name }
  end

  def new_item(klass = Item)
    klass.new(@db)
  end

  def new_lparstat_out(options = {})
    @db.create_item('lparstat.out').tap do |lparstat_out|
      lparstat_out['Node Name'] = options[:node_name] || new_node_name
      lparstat_out['Partition Name'] = options[:partition_name] || new_partition_name
    end
  end

  def new_sys0(options = {})
    new_device(options.merge({ name: 'sys0'})).tap do |sys0|
      add_attr(sys0, :id_to_system, options[:id_to_system] || system_num )
      add_attr(sys0, :id_to_partition, options[:id_to_partition] || lpar_num )
      add_attr(sys0, :fwversion, options[:fwversion] || "IBM,fw12345" )
      add_attr(sys0, :modelname, options[:modelname] || "IBM,model9876" )
    end
  end

  def new_inet0(options)
    new_device(options.merge({ name: 'inet0' })).tap do |inet0|
      add_attr(inet0, :hostname, options[:hostname] || hostname_num)
    end
  end
  
  # Creates a new Db settings {Db#date_time} either to what is passed
  # in options or the next in a count sequence.
  def new_db(options)
    @db = (Db.new.tap { |db| db.date_time = options[:date_time] || new_db_num })
  end

  def new_dev_num
    @dev_num ||= 0
    @dev_num += 1
  end

  def new_db_num
    @db_num ||= 0
    @db_num += 1
  end

  def system_num
    @system_num ||= 0
  end

  def lpar_num
    @lpar_num ||= 0
  end

  def hostname_num
    "host#{lpar_num}"
  end
end

  # @@cec_number = 1
  # @@lpar_number = 1
  # @@snap_number = 1
  # @@dev_number = 1
  # @@vlan_number = 1
  # @@db = nil

  # def start_new_cec
  #   @@cec_number += 1
  #   new_lpar
  # end

  # def start_new_lpar
  #   @@lpar_number += 1
  #   new_snap
  # end

  # def new_snap
  #   @@snap_number += 1
  #   @@db = nil
  # end

  # def new_item
  #   Item.new(db)
  # end

  # # Creates a device with prefix and adds it to Devices
  # # @param prefix [String] device prefix such as +ent+ to produce
  # # +ent0+.
  # def device(prefix)
  #   item = new_item
  #   name = "%s%d" % [ prefix, @@dev_number += 1]
  #   item[:name] = name
  #   devices = (db["Devices"] ||= new_item)
  #   devices[name] = item
  #   item
  # end

  # def ent
  #   item = device("ent")
  #   item['entstat'] = new_item
  #   item
  # end
  
  # def sea(options = {})
  #   item = ent
  # end

  # private

  # def db
  #   @@db ||= Db.new
  # end
# end

# module FakeBatch
#   @@global = 0

#   puts "In FakeBatch #{self.name} #{self.class}"

#   class << self
#     def orange
#       puts "I am orange"
#     end

#     def included(mod)
#       puts "I am included! #{mod.name}"
#       class << mod
#         def puppy
#           puts "I am a puppy!!!"
#         end
#       end
#     end
#   end

#   def instance_blah
#     "Instance Blah"
#   end

#   def fake_batch(options = {})
#     FakeBatch.orange
#     self.class.dog
#     self.class.puppy
#     # self.class.puppy
#     @@global += 1
#     @banana = @@global unless @banana
#     puts "fake_batch"
#     snaps = options[:snaps].map { |snap| fake_snap(snap) }
#     Batch.new(snaps)
#   end

#   def adjust_object(obj, list)
#     list.each do |method, result, proc|
#       if obj.respond_to?(method) && (obj.send(method) == result)
#         proc.call(obj)
#       end
#     end
#   end

#   def adjust_item(item, list)
#     adjust_object(item, list)
#     item.each_pair do |k, v|
#       adjust_item(v, list) if v.is_a?(Item)
#     end
#   end

#   def adjust_batch(batch, list)
#     batch.each_cec do |cec|
#       adjust_object(cec, list)
#       cec.each_lpar do |lpar|
#         adjust_object(lpar, list)
#         lpar.each_snap do |snap|
#           adjust_object(snap, list)
#           adjust_item(snap.db, list)
#         end
#       end
#     end
#     batch
#   end

#   def expect_no_alerts(batch)
#     expect(batch).not_to receive(:add_alert)
#     batch.each_cec do |cec|
#       expect(cec).not_to receive(:add_alert)
#       cec.each_lpar do |lpar|
#         expect(lpar).not_to receive(:add_alert)
#         lpar.each_snap do |snap|
#           expect(snap).not_to receive(:add_alert)
#         end
#       end
#     end
#     batch
#   end

#   def fake_snap(options = {})
#     dir = (options[:dir] || "none")
#     db = Db.new

#     options[:db].each_pair do |k, v|
#       v = [ v ] unless v.is_a?(Array)
#       v.each do |f|
#         item = db.create_item(k.to_s)
#         fake_item(item, f, db)
#       end
#     end
#     db.date_time = DateTime.parse(options[:date_time]) if options.has_key?(:date_time)

#     Snap.new(db: db, dir: dir )
#   end

#   def fake_item(item, attrs, db)
#     attrs.each_pair do |k, v|
#       if v.is_a?(Hash)
#         item[k] = fake_item(Item.new(db), v, db)
#       elsif v.is_a?(Array)
#         item[k] = v.map { |h| fake_item(Item.new(db), h, db) }
#       else
#         item[k] = v
#       end
#     end
#     item
#   end

#   def fake_attr(value)
#     { value: value }
#   end
# end

# def batch1
#   {
#     snaps: [ snap1 ]
#   }
# end

# def snap1
#   {
#     dir: "/some/path",
#     date_time: "Fri Dec 25 19:31:01 CST 2015",
#     db: {
#       devices: {
#         sys0: sys0_1,
#         inet0: inet0_1,
#         ent16: sea16,
#         ent15: vea15,
#       },
#       seas: {
#         ent16: sea16,
#       }
#     }
#   }
# end

# def sys0_1
#   {
#     attributes: {
#       id_to_partition: fake_attr("1"),
#       id_to_system: fake_attr("1"),
#       fwversion: fake_attr("IBM,fw12345"),
#       modelname: fake_attr("IBM,model12345")
#     }
#   }
# end

# def inet0_1
#   {
#     attributes: {
#       hostname: fake_attr("snap1")
#     }
#   }
# end

# def sea16
#   {
#     name: "ent16",
#     super: ent16,
#     real_adapter: ent0,
#     virt_adapters: [ vea15 ],
#     ctl_chan: nil
#   }
# end

# def ent16
#   {
#     name: "ent16",
#     attributes: {
#       ha_mode: fake_attr("auto"),
#       ctl_chan: fake_attr(""),
#       pvid_adapter: fake_attr("ent15")
#     }
#   }
# end

# def vea15
#   {
#     name: "ent15",
#     entstat: {
#       "Port VLAN ID" => 199,
#       "Receive Information" => {
#         "Receive Buffers" => {
#           "Control" => {
#           }
#         }
#       }
#     }
#   }
# end

# def ent0
#   {
#     name: "ent0"
#   }
# end
