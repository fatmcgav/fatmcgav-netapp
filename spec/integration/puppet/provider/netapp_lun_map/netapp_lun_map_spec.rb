#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'


describe Puppet::Type.type(:netapp_lun_map).provider(:netapp_lun_map) do

  device_conf =  YAML.load_file(my_fixture('device_conf.yml'))
  before :each do
    Facter.stubs(:value).with(:url).returns(device_conf['url'])
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_lun_map).stubs(:defaultprovider).returns described_class
  end

  let :lun_map do
    Puppet::Type.type(:netapp_lun_map).new(
      :name     => '/vol/testVolume/testLun1',
      :ensure   => :present,
      :initiatorgroup   => 'TestGroupNetApp'
    )
  end

  let :lun_unmap do
    Puppet::Type.type(:netapp_lun_map).new(
      :name     => '/vol/testVolume/testLun1',
      :ensure   => :present,
      :initiatorgroup   => 'TestGroupNetApp'
    )
  end

 
  let :provider do
    described_class.new( )
  end
  
  describe "when asking exists?" do
    it "should return false if lun is not mapped" do
      lun_map.provider.should_not be_exists
    end
  end

  describe "when mapping a lun" do
    it "should be able to map a lun" do
      lun_map.provider.should_not be_exists
      lun_map.provider.create
    end
  end

  describe "when un-mapping a lun" do
    it "should be able to un-map a lun" do
      lun_unmap.provider.should be_exists
      lun_unmap.provider.destroy
    end
  end

end