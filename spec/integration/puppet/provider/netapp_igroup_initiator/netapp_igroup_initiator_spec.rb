#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/provider/netapp'
require 'puppet/util/network_device/netapp/device'

describe Puppet::Type.type(:netapp_igroup_initiator).provider(:netapp_igroup_initiator) do

  device_conf_yml =  YAML.load_file(my_fixture('device_conf.yml'))
  url_node = device_conf_yml['DeviceURL']
  before :each do
    Facter.stubs(:value).with(:url).returns(url_node['url'])
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_igroup_initiator).stubs(:defaultprovider).returns described_class
  end

  #Load Add initiator in iGroup file
  add_initiator_yml =  YAML.load_file(my_fixture('add_initiator.yml'))

  create_node = add_initiator_yml['AddInitiator1']
  let :add_initiator do
    Puppet::Type.type(:netapp_igroup_initiator).new(
                :name                   => create_node['name'],
                :ensure                 => create_node['ensure'],
                :initiator              => create_node['initiator'],
        )
  end


  #Load remove initiator in iGroup file
  remove_initiator_yml = YAML.load_file(my_fixture('remove_initiator.yml'))

  remove_node = remove_initiator_yml['RemoveInitiator1']
  let :remove_initiator do
    Puppet::Type.type(:netapp_igroup_initiator).new(
                :name                   => remove_node['name'],
                :ensure                 => create_node['ensure'],
                :initiator              => create_node['initiator'],
    )
  end
  
  #Load the provider
  let :provider do
    described_class.new( )
  end


  describe "iGroup initiator should not exists" do
    it ":iGroup initiator should not exists" do
      add_initiator.provider.should_not be_exists
    end
  end
  
  describe "add initiator in igroup" do
    it ":should be able to add initiator in iGroup" do
      add_initiator.provider.create
    end
  end


  describe "iGroup initiator should exists" do
    it ":iGroup initiator should exists" do
      add_initiator.provider.should be_exists
    end
  end
  
  
  describe "remove initiator from igroup" do
    it ":should be able to remove initiator from igroup" do
      remove_initiator.provider.destroy
    end
  end





end
