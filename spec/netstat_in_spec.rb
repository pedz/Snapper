require "spec_helper"
require "netstat_in"

describe Netstat_in do
  before(:all) {
    text = <<EOF

Name  Mtu   Network     Address           Ipkts Ierrs    Opkts Oerrs  Coll
en9   1500  link#2      0.0.c9.d9.e8.bf         0     0       14     0     0
en9   1500  10.201.10   10.201.10.31            0     0       14     0     0
en22  1500  link#3      e4.1f.13.fd.29.75   190896     0   210601     0     0
en22  1500  10.201.52   10.201.55.100      190896     0   210601     0     0
lo0   16896 link#1                           5735     0     5735     0     0
lo0   16896 127         127.0.0.1            5735     0     5735     0     0
lo0   16896 ::1%1                            5735     0     5735     0     0

EOF
    @result = Netstat_in.new(text).result.to_hash
  }

  it "has an entry for each interface" do
    expect(@result.length).to eq(3)
  end

  it "should have an :mtu field for each entry" do
    expect(@result['en9'][:mtu]).to eq(1500)
  end

  it "should have a :mac field for each entry" do
    expect(@result['en9'][:mac]).to eq('0.0.c9.d9.e8.bf')
  end

  it "should have a :ipkts field for each entry" do
    expect(@result['en22'][:ipkts]).to eq(190896)
  end

  it "should have a :ierrs field for each entry" do
    expect(@result['en22'][:ierrs]).to eq(0)
  end

  it "should have a :opkts field for each entry" do
    expect(@result['en22'][:opkts]).to eq(210601)
  end

  it "should have a :oerrs field for each entry" do
    expect(@result['en22'][:oerrs]).to eq(0)
  end

  it "should have a :coll field for each entry" do
    expect(@result['en22'][:coll]).to eq(0)
  end

  it "should have a list of IPv4 configured addresses" do
    expect(@result['lo0'][:inet].length).to eq(1)
  end

  it "should have a list of IPv6 configured addresses" do
    expect(@result['lo0'][:inet6].length).to eq(1)
  end

  it "should have a network and an address for each configured address" do
    expect(@result['en22'][:inet][0][:network]).to eq('10.201.52')
    expect(@result['en22'][:inet][0][:address]).to eq('10.201.55.100')
  end
end
