#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_group).provider(:sevenmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_group).stubs(:defaultprovider).returns described_class
  end
  
  let :group do
    Puppet::Type.type(:netapp_group).new(
      :groupname => 'group',
      :ensure    => :present,
      :comment   => 'test group',
      :roles     => 'role1,role2',
      :provider  => provider
    )    
  end
  
  let :provider do
    described_class.new(
      :groupname => 'group'
    )
  end
  
  describe "#instances" do
    it "should return an array of current group entries" do
      described_class.expects(:glist).returns YAML.load_file(my_fixture('group-list.yml'))
      instances = described_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
          :groupname => prov.get(:groupname),
          :ensure    => prov.get(:ensure),
          :comment   => prov.get(:comment),
          :roles     => prov.get(:roles)
        }
      end.should == [
        {
          :groupname => 'group',
          :ensure    => :present,
          :comment   => 'test group',
          :roles     => 'role1,role2',
        }
      ]
    end
  end
  
  describe "#prefetch" do
    it "exists" do
      described_class.expects(:glist).returns YAML.load_file(my_fixture('group-list.yml'))
      described_class.prefetch({})
    end
  end
  
  describe "when asking exists?" do
    it "should return true if resource is present" do
      group.provider.set(:ensure => :present)
      group.provider.should be_exists
    end

    it "should return false if resource is absent" do
      group.provider.set(:ensure => :absent)
      group.provider.should_not be_exists
    end
  end
  
  describe "when creating a resource" do
    it "should be able to create a group" do    
      group.provider.expects(:gadd).with('useradmin-group', is_a(NaElement))
      group.provider.create
    end
  end
  
  describe "when destroying a resource" do
    it "should be able to destroy a group" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      group.provider.set(:groupname => 'group')
      group.provider.expects(:gdel).with('group-name', 'group')
      group.provider.destroy
      group.provider.flush
    end
  end
  
  describe "when modifying a resource" do
    it "should be able to modify an existing group" do
      # Need to have a resource present that we can modify
      group.provider.set(:groupname => 'group', :ensure => :present, :roles => ['role1'])
      group.provider.expects(:gmodify).with('useradmin-group', is_a(NaElement))
      group.provider.flush
    end
  end
  
end