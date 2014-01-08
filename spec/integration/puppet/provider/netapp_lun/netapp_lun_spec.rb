#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/provider/netapp'
require 'puppet/util/network_device/netapp/device'

describe Puppet::Type.type(:netapp_lun).provider(:netapp_lun) do

  #Load the URL file
  device_conf_yml =  YAML.load_file(my_fixture('device_conf.yml'))
  url_node = device_conf_yml['DeviceURL']

  before :each do
    Facter.stubs(:value).with(:url).returns(url_node['url'])
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_lun).stubs(:defaultprovider).returns described_class
  end

  #Load Create LUN file
  create_lun_yml =  YAML.load_file(my_fixture('create_lun.yml'))

  create_node = create_lun_yml['CreateLUN1']

  let :create_lun do
    Puppet::Type.type(:netapp_lun).new(
    :name     			=> create_node['name'],
    :ensure				=> create_node['ensure'],
    :size_bytes			=> create_node['size_bytes'],
    :ostype				=> create_node['ostype'],
    :space_res_enabled	=> create_node['space_res_enabled']
    )
  end

  #Load Delete LUN file
  delete_lun_yml =  YAML.load_file(my_fixture('delete_lun.yml'))

  delete_node = delete_lun_yml['DeleteLUN1']
  let :delete_lun do
    Puppet::Type.type(:netapp_lun).new(
    :name     			=> delete_node['name'],
    :ensure				=> delete_node['ensure'],
    :force				=> delete_node['force']
    )
  end

  let :provider do
    described_class.new( )
  end

  describe "when not exists?" do
    it ":should return true if lun is not present" do
      delete_lun.provider.should_not be_exists
    end
  end

  describe "create a new lun" do
    it ":should be able to create a lun" do
      create_lun.provider.create
    end
  end

  describe "when exists?" do
    it ":should return true if lun is present" do
      create_lun.provider.should be_exists
    end
  end

  describe "remove the lun" do
    it ":should be able to remove the lun" do
      delete_lun.provider.destroy
    end
  end

end