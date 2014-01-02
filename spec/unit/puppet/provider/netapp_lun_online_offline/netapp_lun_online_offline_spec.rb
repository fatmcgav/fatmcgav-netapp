#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'


describe Puppet::Type.type(:netapp_lun_online_offline).provider(:netapp_lun_online_offline) do

  device_conf =  YAML.load_file(my_fixture('device_conf.yml'))
  before :each do
    Facter.stubs(:value).with(:url).returns(device_conf['url'])
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_lun_online_offline).stubs(:defaultprovider).returns described_class
  end

  let :lun_online do
    Puppet::Type.type(:netapp_lun_online_offline).new(
      :name     => '/vol/testVolume/testLun1',
      :ensure   => :present,
      :force   =>  true
    )
  end

  let :lun_offline do
    Puppet::Type.type(:netapp_lun_online_offline).new(
      :name     => '/vol/testVolume/testLun1',
      :ensure   => :absent,
      :force   =>  true
    )
  end

 
  let :provider do
    described_class.new( )
  end
  
  describe "when asking exists?" do
    it "should return false if lun is not online" do
      lun_online.provider.should_not be_exists
    end
  end

  describe "when executing online operation on lun" do
    it "should be able to online lun" do
      lun_online.provider.should_not be_exists
      lun_online.provider.create
    end
  end

  describe "when executing offline operation on lun" do
    it "should be able to un-map a volume" do
      lun_offline.provider.should be_exists
      lun_offline.provider.destroy
    end
  end

end