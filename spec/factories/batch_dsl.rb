require 'batch'
require 'snap'
require 'date'
require 'time'
require 'hostname'

class Device < Item; end
class Sea < Device;  end

module BatchDSL
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
    options = options.dup       # because we muck with them
    ent = new_ent(options)
    options.delete(:name)       # name would be for the SEA
    name = ent.name

    ent.cu_dv['PdDvLn'] = "adapter/pseudo/sea"

    # The default is to properly create a working SEA that passes all
    # tests.  To do this, we do not create a control channel and that
    # implies that the single virt_adapter will also be the pvid
    # adapter and be use discovery mode.
    #
    # We also put the virt adapter into Trunk mode by specifying
    # allowed of None (if it is not already present)
    virt_options = options.dup
    unless options.has_key?(:ctl_chan)
      virt_options = { discovery: true }.merge(virt_options)
    end
    virt_options = { allowed: "None" }.merge(virt_options)
    virt_adapters = options[:virt_adapters] || [ new_vea(virt_options) ]

    # If :pvid was present and :virt_adapters is not, it would be
    # picked up by virt_adapt.  If we did not, then the user must
    # dance the correct steps.
    unless options.has_key?(:virt_adapters)
      options.delete(:pvid)
      options.delete(:allowed)
    end

    real_adapter = options[:real_adapter] || new_ent(options)
    ctl_chan = options[:ctl_chan]
    pvid_adapter = virt_adapters.first
    pvid = options[:pvid] || pvid_adapter.entstat["Port VLAN ID"]
    
    add_attr(ent, :ctl_chan, ctl_chan ? ctl_chan.name : "")
    add_attr(ent, :ha_mode, options[:ha_mode] || 'auto')
    add_attr(ent, :pvid_adapter, pvid_adapter.name)
    add_attr(ent, :real_adapter, real_adapter.name)
    add_attr(ent, :virt_adapters, virt_adapters.map(&:name).join(','))
    add_attr(ent, :pvid, pvid)
    add_attr(ent, :adapter_reset, options[:adapter_reset] || "no")

    sea = ent.subclass(Sea)
    sea[:ctl_chan] = ctl_chan
    sea[:pvid_adapter] = virt_adapters.first
    sea[:real_adapter] = real_adapter
    sea[:virt_adapters] = virt_adapters
    # batches (used for process_batch testing) start with
    # start_new_cec and need db['seas'] while snaps (used for
    # process_snap testing) can not have it.
    seas[name] = sea if system_num > 0
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
    devices[name] = new_item(Device).tap do |item|
      item[:name] = name
      item['CuDv'] = new_item.tap do |cu_dv|
        cu_dv['PdDvLn'] = "some/random/device"
      end
      item['CuAt'] = []
      item['PdDv'] = []
      item['PdAt'] = []
      item['PdDvLn'] = []
    end
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
