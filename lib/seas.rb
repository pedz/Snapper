require "set"
require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethernets, ethchans, seas, vlans,
# ethernet_adapters, interfaces
require_relative 'ethchans'

# A snap processor that runs through the Devices looking Sea devices.
# This processor must run after Devices but before Vlans and
# Interfaces.
class Seas < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # A class for alerts using class methods so the alerts are available
  # from test units.
  class Alerts
    class << self
      def mismatched_bridge_modes(sea1, bmode1, sea2, bmode2)
        "SEA #{sea1} with bridge mode of #{bmode1} mismatched with SEA #{sea2} in other LPAR with bridge mode of #{bmode2}"
      end


      # Formats the proper alert string when the +pvid+ attribute of the
      # SEA does not match the <tt>Port VLAN ID</tt> of the
      # +pvid_adapter+.
      # @param sea [String] The logical name of the SEA.
      # @param sea_pvid [Integer] The value of the pvid attribute for
      #   the SEA.
      # @param pvid_adapter [String] The value of the pvid_adapter
      #   attribute for the SEA.
      # @param adapter_pvid [Integer] The <tt>Port VLAN ID</tt> value
      #   from the entstat for the pvid_adapter.
      # @return [String] The alert text.
      # @example Sample PVID Mismatch Text
      #   pvid attribute for ent16 of 1234 mismatches ent15's Port VLAN ID of 9876
      def pvid_mismatch(sea, sea_pvid, pvid_adapter, adapter_pvid)
        t = "pvid attribute for #{sea} of #{sea_pvid} mismatches " +
            "#{pvid_adapter}'s Port VLAN ID of #{adapter_pvid}"
      end

      # Formats the proper alert string when the +reset_adapter+
      # attribute of a Sea is not set properly.
      # @param sea [String] The logical name for the SEA.
      # @param value ["yes", "no"] The value of the +reset_adapter+
      #   attribute.
      # @return [String] The alert text.
      # @example  Sample Reset Adapter Text
      #   adapter_reset on ent16 set to "no"
      def reset_adapter_yes(sea, value)
        "adapter_reset on #{sea} set to #{value.inspect}"
      end

      # Formats the proper alert string when a VEA needs to be in
      # trunk mode and it is not.
      # @param sea [String] The logical name for the SEA.
      # @param vea [String] The logical name for the VEA that failed.
      # @return (see reset_adapter_yes)
      # @example Sample Not Trunk Text
      #   VEA ent15 on SEA ent16 must be a Trunk Adapter"
      def not_trunk(sea, vea)
        "VEA #{vea} on SEA #{sea} must be a Trunk Adapter"
      end

      # Formats the proper alert string when a VEA is a Trunk Adapter
      # but it should not be.
      # @param sea [String] The logical name for the SEA.
      # @param vea [String] The logical name for the VEA that failed.
      # @return (see reset_adapter_yes)
      # @example Sample Not Trunk Text
      #   VEA ent15 on SEA ent16 can not b a Trunk Adapter"
      def is_trunk(sea, vea)
        "VEA #{vea} on SEA #{sea} can not be a Trunk Adapter"
      end

      # Formats the proper alert string when two VEAs within the same
      # LPAR are using the same VLAN id on the same virtual switch.
      # @param ent1 [String] The logical name of one of the
      #   conflicting VEAs
      # @param ent2 [String] The logical name of the other of the
      #   conflicting VEAs
      # @param vid [Integer] The VLAN id that is being used by two
      #   VEAs.
      # @param vswitch [String] The virtual switch the two VEAs are
      #   connected to.
      # @return [String] The alert text.
      # @example Sample VID Conflict Text
      #   ent14 and ent15 both use VLAN 42 on ETHERNET0
      def vid_conflict(ent1, ent2, vid, vswitch)
        "#{ent1} and #{ent2} both use VLAN #{vid} on #{vswitch}"
      end

      # Formats the proper alert string when a SEA does not have a
      # mate and the batch contains more than one host with SEAs.
      # @param sea [String] The logical name of the SEA that is not
      #   matched (has no mate in the batch).
      # @return [String] The alert text.
      # @example Same Unmatched SEA Text
      #   Mate to ent16 not found within Snapper run
      def unmatched_sea(sea)
        "Mate to #{sea} not found within Snapper run"
      end

      # Formats the proper alert string when a SEA has more than one
      # _mate_.
      # @param sea [String] The logical name of the SEA in the snap
      #   that has more than two other SEAs using the same virtual
      #   switch and PVID combination.
      # @param vswitch [String] The virtual switch name.
      # @param pvid [Integer] The PVID.
      # @param other_hosts [Array<String>] hostnames of the other
      #   LPARs that have a SEA in the conflict.
      # @return [String] The alert text.
      # @example Sample Over Matched SEAs Text
      #   3 other hosts mate with SEA ent16 using PVID 1234 on ETHERNET0: host5, host8, and host12
      def over_matched_seas(sea, vswitch, pvid, other_hosts)
        count = other_hosts.length
        last_host = other_hosts.pop
        host_list = other_hosts.join(', ')
        host_list += ',' if other_hosts.length > 1
        host_list += " and #{last_host}"
        "#{count} other hosts mate with SEA #{sea} using PVID #{pvid} on " +
          "#{vswitch}: #{host_list}"
      end

      # Formats the proper alert string when a VEA appears to be using
      # discovery protocol but does not have +Control+ buffers
      # allocated.
      # @param sea [String] The logical name of the Sea.
      # @param vea [String] The logical name of the VEA.
      # @return [String] The alert text.
      # @example Sample Discovery VEA Text
      #   VEA ent15 on SEA ent16 should have "Control" buffer type but does not
      def discovery_vea(sea, vea)
        "VEA #{vea} on SEA #{sea} should have \"Control\" buffer type but " +
          "does not"
      end

      # Formats the proper alert string when a SEA's bridge mode is
      # not what it should be.  For example, the bridge mode should be
      # "All" if the state is PRIMARY.
      # @param sea [String] The logical name of the Sea.
      # @param correct [String] The correct value for bridge mode.
      # @param current [String] The current value for bridge mode.
      # @example Sample Bridge Mode not correct Text
      #   SEA ent10 bridge mode should be All but is None
      def bmode_not_correct(sea, correct, current)
        "SEA #{sea} bridge mode should be #{correct} but is #{current}"
      end

      # Formats the proper alert string when a VEA for a SEA should
      # have Active of True and it does not.
      # @param sea [String] The logical name of the Sea.
      # @param vea [String] The Vea that is not active
      # @example Sample Bridge Mode not correct Text
      #   VEA ent15 on ent10 should be Active: True and it is not
      def vea_not_active(sea, vea)
        "VEA #{vea} on #{sea} should be Active: True and it is not"
      end

      # Formats the proper alert string when a VEA for a SEA should
      # have Active of False and it does not.
      # @param sea [String] The logical name of the Sea.
      # @param vea [String] The Vea that is not active
      # @example Sample Bridge Mode not correct Text
      #   VEA ent15 on ent10 should be Active: False and it is not
      def vea_is_active(sea, vea)
        "VEA #{vea} on #{sea} should be Active: False and it is not"
      end

      # Formats the proper alert string when a SEA on the same host
      # changes between snaps.
      # @param sea [String] The logical name of the SEA.
      # @param vswitch [String] The name of the virtual switch.
      # @param pvid [Integer] The PVID
      # @return [String] The alert text.
      # @example Sample SEA Changed Text
      #   SEA ent16 using PVID 1234 on ETHERNET0 differs between snaps
      def sea_changed(sea, vswitch, pvid)
        "SEA #{sea} using PVID #{pvid} on #{vswitch} differs between snaps"
      end

      # Formats the proper alert string when a VEA has been added to
      # the SEA in this snap when compared to snaps of its _mate_.
      # @param sea [String] The logical name for the SEA.
      # @param vea_config [VeaConfig] The configuration for the VEA on
      #   this SEA that has more VLANs allowed than its mate.
      # @return (see sea_changed)
      # @example Sample VEA Added Text
      #   SEA ent16 has additional VEA ent15 with PVID 1234 and VLAN Tag IDs of 12, 13, 14, 15 on ETHERNET0
      def vea_added(sea, vea_config)
        vswitch, pvid, allowed = vea_config.triple
        vea = vea_config.name
        allowed = allowed.join(', ') if allowed.is_a?(Array)
        "SEA #{sea} has additional VEA #{vea} with PVID #{pvid} and VLAN Tag " +
          "IDs of #{allowed} on #{vswitch}"
      end

      # Formats the proper alert string when a VEA is missing from the
      # SEA in this snap when compared to snaps of its _mate_.
      # @param sea [String] The logical name for the SEA.
      # @param vea_config [VeaConfig] The configuration for the VEA on
      #   this SEA that has more VLANs allowed than its mate.
      # @return (see sea_changed)
      # @example Sample VEA Added Text
      #   SEA ent16 is missing a VEA with PVID 1234 and VLAN Tag IDs of 12, 13, 14, 15 on ETHERNET0
      def vea_missing(sea, vea_config)
        vswitch, pvid, allowed = vea_config.triple
        vea = vea_config.name
        allowed = allowed.join(', ') if allowed.is_a?(Array)
        "SEA #{sea} is missing a VEA with PVID #{pvid} and VLAN Tag IDs of " +
          "#{allowed} on #{vswitch}"
      end

      # Formats the proper alert string when a VEA on a SEA has
      # additional allowed VLAN IDs compared to the matching VEA on
      # the matching SEA.
      # @param sea [String] The logical name of the SEA.
      # @param vlans [Array<Integer>] The list of added vlans
      # @param vea_config [VeaConfig] The configuration for the VEA on
      #   this SEA that has more VLANs allowed than its mate.
      # @return (see sea_changed)
      # @example Sample VLAN Added Text
      #   VEA ent15 with PVID 1234 using ETHERNET0 on SEA ent16 has additional VLANs 14, 15 from its mate
      def vlan_added(sea, vlans, vea_config)
        vswitch, pvid, allowed = vea_config.triple
        vea = vea_config.name
        vlan_text = vlans.length == 1 ? "VLAN" : "VLANs"
        "VEA #{vea} with PVID #{pvid} using #{vswitch} on SEA #{sea} has " +
          "additional #{vlan_text} #{vlans.join(', ')} from its mate"
      end

      # Formats the proper alert string when a VEA on a SEA has
      # missing allowed VLAN IDs compared to the matching VEA on
      # the matching SEA.
      # @param sea [String] The logical name of the SEA.
      # @param vlans [Array<Integer>] The list of added vlans
      # @param vea_config [VeaConfig] The configuration for the VEA on
      #   this SEA that has fewer VLANs allowed than its mate.
      # @return (see sea_changed)
      # @example Sample VLAN Added Text
      #   VEA ent15 with PVID 1234 using ETHERNET0 on SEA ent16 is missing VLANs 14, 15 compared to its mate
      def vlan_missing(sea, vlans, vea_config)
        vswitch, pvid, allowed = vea_config.triple
        vea = vea_config.name
        vlan_text = vlans.length == 1 ? "VLAN" : "VLANs"
        "VEA #{vea} with PVID #{pvid} using #{vswitch} on SEA #{sea} is " +
          "missing #{vlan_text} #{vlans.join(', ')} compared to its mate"
      end
    end
  end

  # Wraps, in a single object, how a VEA is configured: the virtual
  # switch it is connected to, the PVID, and the allowed VLANs.  It
  # also includes the name of the VEA but the name is excluded from
  # operations such as equality and ordering.
  # @param vea [Device] The Device entry for a VEA.
  class VeaConfig
    # @return [String] The virtual switch the VEA used to initialize
    #   the instance is connected to.
    attr_reader :vswitch

    # @return [Integer] The PVID of the VEA used to initialize the
    #   instance.
    attr_reader :pvid

    # @return [Array<Integer>] The VLAN Tag IDs of the VEA used to
    #   initialize the instance.
    attr_reader :allowed

    # @return [Array(vswitch, pvid, allowed)]  Used in compares and
    #   many other places.
    attr_reader :triple

    # @return [String] The name of the VEA used to initialize the
    #   instance.
    attr_reader :name

    def initialize(vea)
      @name = vea.name
      if vea['entstat']
        @vswitch, @pvid, @allowed = Seas.vlan_triple(vea.entstat)
      else
        @vswitch = nil
        @pvid = nil
        @allowed = []
      end
      @triple = [ @vswitch, @pvid, @allowed ]
    end

    def triple
      @triple
    end
    alias :to_a :triple
    
    def name
      @name
    end

    def !=(other)
      self.to_a != other.to_a
    end

    def ==(other)
      self.to_a == other.to_a
    end

    def <=>(other)
      self.to_a <=> other.to_a
    end

    def to_s
      {
        vswitch: vswitch,
        pvid: pvid,
        allowed: allowed,
        name: name
      }.to_s
    end
  end

  class << self
    
    # Runs through Devices looking for ones that have a PdDvLn value of
    # +adapter/pseudo/sea+.  When one is found the entry in Devices is
    # altered to be a Sea and at the same time, the real_adapter,
    # virt_adapters, and ctl_chan attributes are added and filled in
    # based upon the attribute values found in the Device item.
    #
    # {Alert}s created for:
    #
    # 1. The <tt>Port VLAN ID</tt> of the +pvid_adapter+ equals the
    #    +pvid+ attr of the SEA.
    #
    # 2. If +adapter_reset+ is set to +yes+.
    #
    # 3. All +virt_adapters+ must be trunk adapters.
    #
    # 4. The +ctl_chan+ must not be a trunk adapter.
    #
    # 5. PVID adapter in discovery mode must have Control buffers.
    #
    # 6. Sanity check bridge mode is All when State is PRIMARY.  Also
    #    bridge mode should be Partial when State is PRIMARY_SH or
    #    BACKUP_SH.
    #
    # 7. Check VEAs are active
    #
    #    a. If bridge mode is All, then all the VEAs should be active.
    #
    #    b. If bridge mode is Partial, then the VEAs for the VID
    #       shared list should be active.
    #
    #    c. If bridge mode is None, then all VEAs should have active
    #       set to false.
    #
    # @param snap [Snap] The snap to process.
    # @param options [Options] The options specified on the command line
    def process_snap(snap, options)
      db = snap.db
      devices = db.devices
      seas = db.create_item("seas")
      devices.each_pair do |logical_name, device|
        if device.cu_dv.pd_dv_ln == "adapter/pseudo/sea"
          sea = convert_to_sea(snap, logical_name, device)

          # Test 1 -- PVID matches PVID...
          check_pvid(snap, sea)

          # Test 2 -- adapter_reset (if present) should be no
          check_reset_adapter(snap, sea)

          # Test 3 -- virt_adapter must be trunk adapters
          check_virt_adapters(snap, sea)

          # Test 4 -- ctl_chan must not be trunk adapter
          check_ctl_chan(snap, sea)

          # Test 5 -- PVID adapter in discovery mode must have Control buffers
          unless sea[:ctl_chan] ||
                 sea.attrs['ha_mode'] == 'disabled' ||
                 sea.attrs['ha_mode'].nil? # no PdAt in snap; default is disabled
            verify_discovery_vea(snap, sea, sea[:pvid_adapter])
          end

          # Test 6 -- check state and bridge mode combination
          check_state_and_bridge_mode(snap, sea)

          # Test 7 -- check active status on VEAs
          check_active_status(snap, sea)
        end
      end
      snap.add_item(seas, 25)
    end

    def caught_rescue(e)
      rescues << e
    end

    def rescues
      @rescues ||= []
    end

    private

    # Converts an Device into a Sea and replaces the entry in
    # Devices.
    # @param snap [Snap] The snap the device came from.
    # @param logical_name [String] The logical name for the device.
    # @param device [Device] The Device for the Sea.
    # @return [Sea] The converted Sea.
    def convert_to_sea(snap, logical_name, device)
      logger.debug { "Converting #{logical_name} into a Sea"}
      db = snap.db
      devices = db['Devices']
      seas = db['seas']
      attrs = device.attributes
      sea = device.subclass(Sea)
      sea[:real_adapter] = devices[attrs.real_adapter.value]
      sea[:virt_adapters] = List.new
      attrs.virt_adapters.value.split(',').each do |adapter_name|
        sea[:virt_adapters].push(devices[adapter_name])
      end
      if attrs.has_key?(:ctl_chan)
        sea[:ctl_chan] = devices[attrs.ctl_chan.value]
      end
      sea[:pvid_adapter] = devices[attrs.pvid_adapter.value]
      devices[logical_name] = sea
      seas[logical_name] = sea
      sea
    end

    # Checks if the +pvid+ attribute for the SEA matches the <tt>Port
    # VLAN ID</tt> of the +pvid_adapter+.  If they do not match, a
    # {Alerts.pvid_mismatch} alert is added to the snap.
    # @param snap [Snap] The snap that contains the SEA.
    # @param sea [Sea] The SEA to check.
    def check_pvid(snap, sea)
      devices = snap.db.devices
      sea_attrs = sea.attributes
      sea_pvid = sea_attrs.pvid.value.to_i
      pvid_adapter = sea_attrs.pvid_adapter.value
      pvid_device = devices[pvid_adapter]
      pvid_entstat = pvid_device['entstat']
      adapter_pvid = pvid_entstat['Port VLAN ID']
      unless sea_pvid == adapter_pvid
        t = Alerts.pvid_mismatch(sea.name, sea_pvid, pvid_adapter, adapter_pvid)
        snap.add_alert(t)
      end
    rescue => e
      caught_rescue(e)
    end
    
    # Checks if the reset_adapter attribute is set to _no_.  If it not
    # set to _no_, adds a {Alerts.reset_adapter_yes} alert to the
    # snap.
    # @param (see check_pvid)
    def check_reset_adapter(snap, sea)
      if (value = sea.attrs[:adapter_reset]) && value != "no"
        t = Alerts.reset_adapter_yes(sea.name, value)
        snap.add_alert(t)
      end
    rescue => e
      caught_rescue(e)
    end

    # Checks if all of the adapters listed in the virt_adapters list
    # are trunk adapters and adds {Alerts.not_trunk} for each which is
    # not.
    # @param (see check_pvid)
    def check_virt_adapters(snap, sea)
      sea.virt_adapters.each do |vea|
        next unless (e = vea['entstat'])
        if e['Trunk Adapter'] != "True"
          snap.add_alert(Alerts.not_trunk(sea.name, vea.name))
        else
          # {EthernetAdapters} checks all VEAs and flags the Trunk
          # Adapters unless this attribute is true.
          vea[:is_trunk] = true
        end
      end
    rescue => e
      caught_rescue(e)
    end

    # Alerts if ctl_chan is a trunk adapter and adds {Alerts.is_trunk}
    # if it is.
    # @param (see check_pvid)
    def check_ctl_chan(snap, sea)
      if (ctl_chan = sea.ctl_chan) &&
         ctl_chan.entstat.trunk_adapter != "False"
        snap.add_alert(Alerts.is_trunk(sea.name, ctl_chan.name))
      end
    rescue => e
      caught_rescue(e)
    end

    public
    
    # First, processes the batch as a sequence of independent CECs.
    # @param batch [Batch] The batch to process.
    def process_batch(batch, options)
      batch.each_cec do |cec|
        review_cec(cec)
      end
    end

    private

    # First, process the CEC as a sequence of independent LPARs.  Then
    # review for errors between LPARs.
    # @param cec [CEC] The cec to process.
    def review_cec(cec)
      @pvid_vswitch_hash = {}
      @hosts_with_seas = Set.new
      cec.each_lpar do |lpar|
        review_lpar(lpar)
      end
      flag_bad_matched_seas
      flag_non_congruent_seas
    end

    # This routine alerts to SEAs that do not have a mate within the
    # snapper run if the run has more than one host with a SEA.  It
    # also alerts if more than two LPARs have SEAs using the same PVID
    # and virtual switch combination.
    #
    # {.process_snap} should flag individual snaps that have
    # conflicting SEAs within the same snap.  They are not flagged
    # here.
    def flag_bad_matched_seas
      return unless @hosts_with_seas.length > 1
      @pvid_vswitch_hash.each_pair do |id, host_hash|
        case host_hash.keys.length
        when 1                  # unmatched
          host, array = host_hash.first
          array.each do |hash|
            t = Alerts.unmatched_sea(hash[:sea].name)
            hash[:snap].add_alert(t)
          end
          
        # When we have one snap for each VIOS, we assume that the
        # snaps were taken at the same time and check to make sure
        # that the bridge modes match up correctly.  We don't do this
        # if there are multiple snaps for a VIOS because we're too
        # lazy to figure out, time wise, which snaps to compare.
        # But, in concept, it could be done.
        when 2                  # two hosts on this pvid+vswitch id
          skip_it = false
          bmodes = []
          seas = []
          snaps = []
          host_hash.each_pair do |host, array|
            if array.length > 1
              skip_it = true
              break
            end
            next unless (sea = array.first[:sea])
            next unless (snap = array.first[:snap])
            next unless (entstat = sea['entstat'])
            next unless (bmode = entstat['Bridge Mode'])
            bmodes.push(bmode)
            snaps.push(snap)
            seas.push(sea)
          end
          next if skip_it || (bmodes.length != 2)
          case bmodes[0]
          when "All"
            next if bmodes[1] == "None"

          when "None"
            next if bmodes[1] == "All"

          when "Partial"
            next if bmodes[1] == "Partial"

          end
          t = Alerts.mismatched_bridge_modes(seas[0].name, bmodes[0], seas[1].name, bmodes[1])
          snaps[0].add_alert(t)
          t = Alerts.mismatched_bridge_modes(seas[1].name, bmodes[1], seas[0].name, bmodes[0])
          snaps[1].add_alert(t)

        else                    # more than 2 hosts
          hosts = host_hash.keys
          hosts.each do |host|
            array = host_hash[host]
            array.each do |hash|
              other_hosts = (hosts - [ host ])
              t = Alerts.over_matched_seas(hash[:sea].name,
                                           hash[:vswitch], 
                                           hash[:pvid],
                                           other_hosts)
              hash[:snap].add_alert(t)
            end
          end
        end
      end
    end

    # What the <b>@#$%</b> is a <em>non-coongruent</em> SEA?  Take SEA
    # 1 in LPAR 1 and SEA 2 in LPAR 2 where they both use the same
    # PVID and virtual switch for their control channel.  These are
    # _mates_ to one another.
    #
    # See the first paragraph of {.register_sea_vswitch_pvid} for
    # exact details of what <em>they both use the same PVID and
    # virtual switch for their control channel</em> means.
    #
    # _mates_ should go on and have the same number of VEAs.  The VEAs
    # are matched up by their PVID and virtual switch.  The mating
    # VEAs should have the same list of VLAN Tag IDs.
    #
    # If all of that is not true, the two SEAs are called
    # <em>non-congruent</em>.
    #
    # Fortunately, congruency is rather easy to test for.  Things must
    # match exactly.  The _ick_ comes up when things don't match and
    # producing useful alerts.
    def flag_non_congruent_seas
      @pvid_vswitch_hash.each_pair do |id, host_hash|
        next if host_hash.keys.length > 2
        all = Set.new
        host_hash.each_pair do |host, array|
          host_set = Set.new
          array.each do |hash|
            vea_config_list = hash[:vea_config_list]
            vea_config_list = vea_config_list.map(&:triple)
            host_set.add(vea_config_list) # remove VEA name
          end

          # If we have multiple snaps for the same host and the SEA
          # changes over time, we will hit this condition.  In this
          # case, we are going to flag the snaps for that host but not
          # the snaps for other hosts.  The user will need to figure
          # out which snaps to keep and which ones to throw out in
          # subsequent runs of Snapper.
          if host_set.length > 1 
            array.each do |hash|
              t = Alerts.sea_changed(hash[:sea].name, hash[:vswitch], hash[:pvid])
              hash[:snap].add_alert(t)
            end
          else
            all.add(host_set)
          end
        end
        next unless all.length > 1

        # here is the ick I mentioned before.
        #
        # So....  What do we know at this point?
        #
        # Any SEAs that are over matched have been thrown out by the
        # "next if" at the top of the method.  Thus the host_hash has
        # 1 or 2 keys.
        #
        # Any host with multiple snaps that changed have also been
        # thrown out by the sea_changed alert.  That would leave only
        # one host in that case and the all.set would have at most 1
        # entry so that has been thrown out as well.
        #
        # That leaves us with exactly two hosts and we know that all
        # the snaps within each host match.  Thus we can pick one snap
        # from each host, compare them, determine the proper alert
        # strings, and then add them to all of the snaps.
        host_hash_copy = host_hash.dup
        host1, array1 = host_hash_copy.shift
        hash1 = array1.first    # they are all the same -- just pick one
        vea_config_list1 = hash1[:vea_config_list]
        host2, array2 = host_hash_copy.shift
        hash2 = array2.first    # they are all the same -- just pick one
        vea_config_list2 = hash2[:vea_config_list]
        alerts1 = []
        alerts2 = []
        while vea_config_list1.length > 0 || vea_config_list2.length > 0
          v1 = vea_config_list1[0]
          v2 = vea_config_list2[0]

          # We match. shift one off each vea_config_list and move on.
          if v1 == v2
            vea_config_list1.shift
            vea_config_list2.shift
            next
          end
          
          if vea_config_list1.empty?
            # case 1
            a = vea_config_list2.shift
            alerts1.push([:vea_missing, a])
            alerts2.push([:vea_added, a])
          elsif vea_config_list2.empty?
            # case 2
            a = vea_config_list1.shift
            alerts1.push([:vea_added, a])
            alerts2.push([:vea_missing, a])
          else
            # if same switch and pvid
            if v1.triple[0 .. 1] == v2.triple[0 .. 1] 
              allowed1 = v1.allowed
              allowed2 = v2.allowed
              added1 = allowed1 - allowed2
              added2 = allowed2 - allowed1
              unless added1.empty?
                alerts1.push([:vlan_added, added1, v1]) 
                alerts2.push([:vlan_missing, added1, v2])
              end
              unless added2.empty?
                alerts1.push([:vlan_missing, added2, v1])
                alerts2.push([:vlan_added, added2, v2])
              end
              vea_config_list1.shift
              vea_config_list2.shift
            else
              # vswitch and pvid differ so shift off the lowest one
              if (v1 <=> v2) < 0 # v1 < v2
                # case 3
                a = vea_config_list1.shift
                alerts1.push([:vea_added, a])
                alerts2.push([:vea_missing, a])
              else
                # case 4
                a = vea_config_list2.shift
                alerts1.push([:vea_missing, a])
                alerts2.push([:vea_added, a])
              end
            end
          end
        end
        
        combined_alerts = [ alerts1, alerts2 ]
        host_hash.each_pair do |host, array|
          alerts = combined_alerts.shift
          array.each do |hash|
            alerts.each do |alert|
              type = alert.shift
              case type
              when :vea_added
                t = Alerts.vea_added(hash[:sea].name, alert.shift)
              when :vea_missing
                t = Alerts.vea_missing(hash[:sea].name, alert.shift)
              when :vlan_added
                t = Alerts.vlan_added(hash[:sea].name, alert[0], alert[1])
              when :vlan_missing
                t = Alerts.vlan_missing(hash[:sea].name, alert[0], alert[1])
              end
              hash[:snap].add_alert(t)
            end
          end
        end
      end
    end

    def review_lpar(lpar)
      lpar.each_snap do |snap|
        review_snap(snap) if snap.db["seas"]
      end
    end

    def review_snap(snap)
      @vlans = {}
      snap.db.seas.each_pair do |logical_name, sea|
        unless logical_name.to_s == sea.name.to_s
          fail "logical_name of #{logical_name} and sea.name of #{sea.name} do not match"
        end
        review_sea(snap, sea)
      end
    end

    def review_sea(snap, sea)
      # Add vlans used by virt_adapters and ctl_chan
      check_sea_vlans(snap, sea)
      register_sea_vswitch_pvid(snap, sea)
    end

    # Each SEA uses a PVID and virtual switch for its control
    # packets.  If the SEA has an explicit control channel using the
    # +ctl_chan+ attribute, then the SEAs control PVID is the PVID of
    # the VEA specified by +ctl_chan+.  If no +ctl_chan+ is specified,
    # then <em>discovery protocol</em> is used.  In that case, the
    # control PVID is the PVID used by the +pvid_adapter+.
    #
    # This routine is the first pass of a three pass process.  It is
    # called for each SEA in the batch and creates a table used by
    # {.flag_bad_matched_seas} and {.flag_non_congruent_seas} passes.
    # @param (see review_sea)
    def register_sea_vswitch_pvid(snap, sea)
      ha_mode = sea.attrs[:ha_mode]

      control_adapter = sea[:ctl_chan] || sea[:pvid_adapter]
      return unless (entstat = control_adapter['entstat'])
      vswitch, pvid, allowed = vlan_triple(entstat)
      sea[:vswitch_pvid] = "#{vswitch}:#{pvid}"

      @hosts_with_seas.add(snap.hostname)
      vea_config_list = []
      sea[:virt_adapters].each do |vea|
        next unless (e = vea['entstat'])
        # We add the VEA name at the end.  Later in
        # flag_non_congruent_seas we trim it off during the compares.
        # But it helps with the alert messages.
        vea_config_list.push(VeaConfig.new(vea))
      end
      vea_config_list.sort!
      id = "%#{vswitch}-#{pvid}"
      t = (@pvid_vswitch_hash[id] ||= {})
      t = (t[snap.hostname] ||= [])
      t.push({ snap: snap, sea: sea, vswitch: vswitch, pvid: pvid,
               allowed: allowed, vea_config_list: vea_config_list})
    end

    # Verifies that the VEA has +Control+ buffers allocated to it.  If
    # it does not, a {Alerts.discovery_vea} alert is added to the
    # snap.
    # @param snap [Snap] The Snap being processed.
    # @param sea [Sea] The SEA being checked.
    # @param vea [Device] The VEA to check.
    def verify_discovery_vea(snap, sea, vea)
      return unless (d = vea['entstat'])
      [ "Receive Information", "Receive Buffers", "Control" ].each do |attr|
        d = d[attr] if d
      end
      snap.add_alert(Alerts.discovery_vea(sea.name, vea.name)) unless d
    end

    State_to_Bridge_Mode_Map = {
      "BACKUP" => "None",
      "BACKUP_SH" => "Partial",
      "LIMBO" => "None",
      "PRIMARY" => "All",
      "PRIMARY_SH" => "Partial"
    }

    # Creates an alert if the SEA State is PRIMARY and the Bridge Mode
    # is not All.  Also creates an alert if the SEA State is
    # PRIMARY_SH or BACKUP_SH and the Bridge Mode is not PARTIAL.
    # @param snap [Snap] The Snap being processed.
    # @param sea [Sea] The SEA being checked.
    def check_state_and_bridge_mode(snap, sea)
      return unless (e = sea['entstat'])
      return unless (state = e['State']) && (bridge_mode = e['Bridge Mode'])
      return unless (correct = State_to_Bridge_Mode_Map[state])
      snap.add_alert(Alerts.bmode_not_correct(sea.name, correct, bridge_mode)) unless correct == bridge_mode
    end

    # Creates alerts if the Active flag for the VEAs is not set
    # properly.  This keys from the Bridge Mode rather than the
    # State.
    # @param snap [Snap] The Snap being processed.
    # @param sea [Sea] The SEA being checked.
    def check_active_status(snap, sea)
      return unless (e = sea['entstat'])
      return unless (state = e['State']) && (bridge_mode = e['Bridge Mode'])
      correct = State_to_Bridge_Mode_Map[state]
      return unless correct == bridge_mode

      case bridge_mode
      when "None"
        sea[:virt_adapters].each do |vea|
          next unless (e = vea['entstat'])
          if e['Trunk Adapter'] == "True"
            snap.add_alert(Alerts.vea_is_active(sea.name, vea.name)) unless e['Active'] == "False"
          end
        end

      when "Partial"
        return unless (shared = e['VID shared'])
        # One of the features of our parsing is sometimes shared is a
        # single integer.
        if shared.respond_to?(:split)
          shared = shared.split(' ').map(&:to_i)
        else
          shared = [ shared ]
        end
        sea[:virt_adapters].each do |vea|
          next unless (e = vea['entstat'])
          if e['Trunk Adapter'] == "True"
            if shared.include?(e['Port VLAN ID'])
              snap.add_alert(Alerts.vea_not_active(sea.name, vea.name)) unless e['Active'] == "True"
            else
              snap.add_alert(Alerts.vea_is_active(sea.name, vea.name)) unless e['Active'] == "False"
            end
          end
        end

      when "All"
        sea[:virt_adapters].each do |vea|
          next unless (e = vea['entstat'])
          if e['Trunk Adapter'] == "True"
            snap.add_alert(Alerts.vea_not_active(sea.name, vea.name)) unless e['Active'] == "True"
          end
        end
      end
    end

    # Checks the VLANs used by the +sea+ and adds alerts if conflicts
    # are found.
    # @param snap [Snap] Used to add alerts
    # @param sea [Sea] The SEA we are processing
    def check_sea_vlans(snap, sea)
      check_ent_vlans(snap, sea[:ctl_chan]) if sea[:ctl_chan]
      sea[:virt_adapters].each { |ent| check_ent_vlans(snap, ent) }
    end

    # Checks the <tt>Port VLAN ID</tt> and the <tt>VLAN Tag IDs</tt>
    # of +ent+.
    # @param snap [Snap] Used to add alerts
    # @param ent [Device] The ent we are processing
    def check_ent_vlans(snap, ent)
      return unless (entstat = ent['entstat'])
      vswitch, pvid, allowed = vlan_triple(entstat)
      name = ent.name
      check_vlan(snap, name, vswitch, pvid)
      if allowed.is_a?(Array)
        allowed.each { |vid| check_vlan(snap, name, vswitch, vid) }
      end
    end

    # Checks a single virtual switch vlan id combination and adds a
    # {Alerts.vid_conflict} alert if a conflict is found.
    # @param snap [Snap] The Snap being processed.
    # @param vea [String] The logical name of the VEA being processed.
    # @param vswitch [String] The virtual switch name the VEA is connected to.
    # @param vid [Integer] The VLAN id to check.
    def check_vlan(snap, vea, vswitch, vid)
      index = "#{vswitch}-#{vid}"
      if (other_vea = @vlans[index])
        snap.add_alert(Alerts.vid_conflict(other_vea, vea, vid, vswitch))
      else
        @vlans[index] = vea
      end
    end

    public
    
    # From the entstat, returns the <tt>Switch ID</tt>, the <tt>Port
    # VLAN ID</tt>, and the <tt>VLAN Tag IDs</tt>.
    # @param entstat [Entstat] The entstat from a VEA.
    # @return [Array(Sting, Integer, Array<Integer>)] virtual switch
    #   name, PVID, Allowed VLAN IDs.
    def vlan_triple(entstat)
      [
        entstat['Switch ID'],
        entstat['Port VLAN ID'],
        entstat['VLAN Tag IDs']
      ]
    end
  end

  Snapper.add_snap_processor(self)
  Snapper.add_batch_processor(self)
end
