require_relative 'logging'
require_relative 'item'
require_relative 'snapper'
# The load order is devices, ethchans, seas, vlans, interfaces
require_relative 'ethchans'

# A snap processor that runs through the Devices looking Sea devices.
# This processor must run after Devices but before Vlans and
# Interfaces.
class Seas < Item
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  class Foo
    # @return [Snap] the snap
    attr_reader :snap
    # @return [Lpar] the LPAR
    attr_reader :lpar
    # @return [Sea] the SEA
    attr_reader :sea

    def initialize(options)
      @snap = options[:snap]
      @sea  = options[:sea]
      @lpar = options[:lpar]
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
    #   1. The <tt>Port VLAN ID</tt> of the +pvid_adapter+ equals the
    #      +pvid+ attr of the SEA
    #
    #   2. If +adapter_reset+ is set to +yes+.
    #
    # @param snap [Snap] The snap to process.
    def process_snap(snap)
      db = snap.db
      devices = db.devices
      seas = db.create_item("seas")
      devices.each_pair do |key, device|
        if device.cudv.pddvln == "adapter/pseudo/sea"
          sea_attrs = device.attributes
          logger.debug { "Converting #{key} into a Sea"}
          new_device = device.subclass(Sea)
          new_device[:real_adapter] = db['Devices'][sea_attrs.real_adapter.value]
          new_device[:virt_adapters] = List.new
          sea_attrs.virt_adapters.value.split(',').each do |adapter_name|
            new_device[:virt_adapters].push(db['Devices'][adapter_name])
          end
          new_device[:ctl_chan] = db['Devices'][sea_attrs.ctl_chan.value]
          devices[key] = new_device
          seas[key] = new_device

          # Test 1 -- PVID matches PVID...
          begin
            pvid = sea_attrs.pvid.value.to_i
            pvid_adapter = sea_attrs.pvid_adapter.value
            pvid_device = devices[pvid_adapter]
            pvid_entstat = pvid_device['entstat']
            pvid_pvid = pvid_entstat['Port VLAN ID']
            snap.add_alert("pvid attribute for #{key} of #{pvid} mismatches #{pvid_adapter}'s Port VLAN ID of #{pvid_pvid}") unless pvid == pvid_pvid
          rescue
          end

          # Test 2 -- adapter_reset (if present) should be no
          begin
            if sea_attrs.adapter_reset.value != "no"
              snap.add_alert("adapter_reset on #{key} set to #{sea_attrs.adapter_reset.value.inspect}")
            end
          rescue
          end
        end
      end
      snap.add_item(seas, 25)
    end

    # First, processes the batch as a sequence of independent LPARs.
    # @param batch [Batch] The batch to process.
    def process_batch(batch)
      batch.each_cec do |cec|

        seas_by_control_pvid = {}

        cec.each_lpar do |lpar|
          lpar.each_snap do |snap|
            next unless (seas = snap.db["seas"])

            devices = snap.db.devices # need this for later

            seas.each_pair do |logical_name, sea|
              attrs = sea.super.attributes
              ha_mode = attrs.ha_mode.value
              next if ha_mode == "disabled" || ha_mode == "standby"
              ctl_chan = attrs.ctl_chan.value
              if ctl_chan.empty?
                pvid_adapter = attrs.pvid_adapter.value
                control = pvid_adapter
              else
                control = ctl_chan
              end

              next unless (control_device = devices[control]) &&
                          (entstat = control_device['entstat']) &&
                          (pvid = entstat["Port VLAN ID"])

              # Remember that we can have multiple snaps for the same
              # hostname.  In that case, we want to check each snap we
              # have and flag the ones we don't like.  This may get
              # chaotic but in general it will never come up.
              ((seas_by_control_pvid[pvid] ||= {})[lpar.hostname] ||= []).push(Foo.new({ snap: snap, sea: sea, lpar: lpar }))

              # An empty control channel implies discovery protocol is
              # being used and in that case, it should have a column
              # for Control packets.  Lets check that to see if it
              # does and if it does not, then the adapter might not be
              # in the proper mode for discovery protocol.
              if ctl_chan.empty?
                d = entstat
                [ "Receive Information", "Receive Buffers", "Control" ].each do |attr|
                  d = d[attr] if d
                end
                unless d
                  snap.add_alert("#{pvid_adapter} on #{sea.name} should have \"Control\" buffer type and it does not")
                end
              end
            end
          end
        end
        seas_by_control_pvid.each_pair do |pvid, hash|
          check_pvid(cec, pvid, hash)
        end
      end
    end

    private

    # @param cec [CEC] the CEC involved
    # @param pvid [Integer] The PVID that was used to match up the
    #   SEAs.
    # @param hash [Hash<String, Foo>] Keys are LPAR hostnames.  Values
    #   are Foo.
    def check_pvid(cec, pvid, hash)
      qb "check_pvid #{pvid} #{hash.keys.length}"
      keys = hash.keys

      # If only one LPAR is using this PVID for a control channel,
      # then even if it changed over time, we would probably just end
      # up producing "errors" for things that were already well
      # understood.
      # return if keys.length == 1

      # While its not illegal to have more than two LPARs with SEAs
      # using the same control channel PVID, it is not done often and
      # probably not what the user wants to do.
      if keys.length > 2
        cec.add_alert("More than two hosts (#{keys.join(',')}) with SEAs using PVID of #{pvid} for their control channel")
      end

      # First we "define" the proper set of PVIDs and Allowed vlans
      # using the SEAs of the first host.  The 2nd and subsequence
      # SEAs should be identical and any differences are noted in the
      # LPAR alerts.
      foos = hash[keys.shift]

      # pick off the last one which will be the newest snap
      last_foo = foos.pop

      # Make a VEAs structure that we consider to be "right"
      target_blah = sea_to_blah(last_foo.sea)

      # Now check the other foos to make sure they match (this is
      # still the defining LPAR)
      foos.each do |other_foo|
        new_blah = sea_to_blah(other_foo.sea)
        diff_blah(target_blah, new_blah, other_foo)
      end

      # Now for the rest of the LPARs
      keys.each do |key|
        # Get the foos for the LPAR and check them
        hash[key].each do |other_foo|
          new_blah = sea_to_blah(other_foo.sea)
          diff_blah(target_blah, new_blah, other_foo)
        end
      end
    end

    def sea_to_blah(sea)
      qb "sea_to_blah #{sea.name}"
      veas = {}
      sea.virt_adapters.each do |virt|
        next unless (entstat = virt.entstat)
        veas[entstat["Port VLAN ID"]] = [ entstat["VLAN Tag IDs"], virt.name ]
      end
      veas
    end

    def diff_blah(target_blah, new_blah, foo)
      target_keys = target_blah.keys
      new_keys = new_blah.keys
      missing_keys = target_keys - new_keys
      added_keys = new_keys - target_keys
      common_keys = target_keys - missing_keys
      snap = foo.snap
      sea = foo.sea
      snap.add_alert("SEA #{sea.name} missing VEA adapters with PVIDs #{missing_keys.join(',')}") unless missing_keys.empty?
      snap.add_alert("SEA #{sea.name} added VEA adapters with PVIDs #{added_keys.join(',')}") unless added_keys.empty?
      # Rinse and repeat
      common_keys.each do |pvid|
        target_allowed, target_vea = target_blah[pvid]
        new_allowed, new_vea = new_blah[pvid]
        missing_allowed = target_allowed - new_allowed
        added_allowed = new_allowed - target_allowed
        snap.add_alert("SEA #{sea.name} missing VLAN#{missing_allowed.length > 1 ? "s" : ""} #{missing_allowed.join(',')} on #{new_vea}") unless missing_allowed.empty?
        snap.add_alert("SEA #{sea.name} added VLAN#{missing_allowed.length > 1 ? "s" : ""} #{added_allowed.join(',')} on #{new_vea}") unless added_allowed.empty?
      end
    end
  end

  Snapper.add_snap_processor(self)
  Snapper.add_batch_processor(self)
end
