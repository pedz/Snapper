require "spec_helper"
require "string"

describe String do
  describe "#snakecase" do
    it "should convert \"HappySam\" to \"happy_sam\"" do
      expect("HappySam".snakecase).to eq("happy_sam")
    end

    it "should convert \"ODM\" to \"odm\"" do
      expect("ODM".snakecase).to eq("odm")
    end

    it "should not change \"something_already_in_snakecase\"" do
      expect("something_already_in_snakecase".snakecase).to eq("something_already_in_snakecase")
    end

    it "should convert \"lsattr -El ent0\" to \"lsattr_el_ent0\"" do
      expect("lsattr -El ent0".snakecase).to eq("lsattr_el_ent0")
    end

    it "should convert \"CuDv\" to \"cu_dv\"" do
      expect("CuDv".snakecase).to eq("cu_dv")
    end
  end

  describe "#camelcase" do
    it "should convert \"lsattr -El ent0\" to \"LsattrElEnt0\"" do
      expect("lsattr -El ent0".camelcase).to eq("LsattrElEnt0")
    end

    it "should preserve \"CuDv\"" do
      expect("CuDv".camelcase).to eq("CuDv")
    end

    it "should convert \"no -a\" to \"NoA\"" do
      expect("no -a".camelcase).to eq("NoA")
    end
  end
end
