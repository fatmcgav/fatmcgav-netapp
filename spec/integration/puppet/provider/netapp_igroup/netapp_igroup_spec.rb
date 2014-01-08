#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/provider/netapp'
require 'puppet/util/network_device/netapp/device'

describe Puppet::Type.type(:netapp_igroup).provider(:netapp_igroup) do

  device_conf_yml =  YAML.load_file(my_fixture('device_conf.yml'))
  url_node = device_conf_yml['DeviceURL']
  before :each do
    Facter.stubs(:value).with(:url).returns(url_node['url'])
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_igroup).stubs(:defaultprovider).returns described_class
  end

  #Load Add Server file
  create_server_yml =  YAML.load_file(my_fixture('create_igroup.yml'))

  create_node = create_server_yml['CreateiGroup1']
  let :create_igroup do
    Puppet::Type.type(:netapp_igroup).new(
                :name                   => create_node['name'],
                :ensure                 => create_node['ensure'],
                :initiatorgrouptype     => create_node['initiatorgrouptype'],
                :ostype                 => create_node['ostype'],
        )
  end


  #Load destroy server
  destroy_igroup_yml = YAML.load_file(my_fixture('destroy_igroup.yml'))

  remove_node = destroy_igroup_yml['DestroyiGroup1']
  let :destroy_igroup do
    Puppet::Type.type(:netapp_igroup).new(
                :name                   => remove_node['name'],
                :ensure                 => create_node['ensure'],
                :initiatorgrouptype     => create_node['initiatorgrouptype'],
    )
  end
  
  #Load the provider
  let :provider do
    described_class.new( )
  end

  describe "igroup should not exists" do
    it ":igroup should not exists" do
      create_igroup.provider.should_not be_exists
    end
  end
  

  describe "create a new igroup" do
    it ":should be able to create iGroup" do
      create_igroup.provider.create
    end
  end

  describe "igroup should exists" do
    it ":igroup should exists" do
      create_igroup.provider.should be_exists
    end
  end

  describe "destroy the igroup" do
    it ":should be able to destroy igroup" do
      destroy_igroup.provider.destroy
    end
  end





end
