
def batch1
  {
    snaps: [ snap1 ]
  }
end

def snap1
  {
    dir: "/some/path",
    date_time: "Fri Dec 25 19:31:01 CST 2015",
    db: {
      devices: {
        sys0: sys0_1,
        inet0: inet0_1,
        ent16: sea16,
        ent15: vea15,
      },
      seas: {
        ent16: sea16,
      }
    }
  }
end

def sys0_1
  {
    attributes: {
      id_to_partition: fake_attr("1"),
      id_to_system: fake_attr("1"),
      fwversion: fake_attr("IBM,fw12345"),
      modelname: fake_attr("IBM,model12345")
    }
  }
end

def inet0_1
  {
    attributes: {
      hostname: fake_attr("snap1")
    }
  }
end

def sea16
  {
    name: "ent16",
    super: ent16,
    real_adapter: ent0,
    virt_adapters: [ vea15 ],
    ctl_chan: nil
  }
end

def ent16
  {
    name: "ent16",
    attributes: {
      ha_mode: fake_attr("auto"),
      ctl_chan: fake_attr(""),
      pvid_adapter: fake_attr("ent15")
    }
  }
end

def vea15
  {
    name: "ent15",
    entstat: {
      "Port VLAN ID" => 199,
      "Receive Information" => {
        "Receive Buffers" => {
          "Control" => {
          }
        }
      }
    }
  }
end

def ent0
  {
    name: "ent0"
  }
end
