#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_role).provider(:netapp_role) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_role).stubs(:defaultprovider).returns described_class
  end
  
  let :role do
    Puppet::Type.type(:netapp_role).new(
      :rolename     => 'role',
      :ensure       => :present,
      :comment      => 'test role',
      :capabilities => 'login-*,cli-*,api-*,security-*',
      :provider     => provider
    )    
  end
  
  let :provider do
    described_class.new(
      :rolename => 'role'
    )
  end
  
  describe "#instances" do
    it "should return an array of current role entries" do
      described_class.expects(:rlist).returns YAML.load_file(my_fixture('role-list.yml'))
      instances = described_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
          :rolename     => prov.get(:rolename),
          :ensure       => prov.get(:ensure),
          :comment      => prov.get(:comment),
          :capabilities => prov.get(:capabilities)
        }
      end.should == [
        {
          :rolename     => 'role',
          :ensure       => :present,
          :comment      => 'test role',
          :capabilities => 'login-*,cli-*,api-*,security-*',
        }
      ]
    end
  end
  
  describe "#prefetch" do
    it "exists" do
      described_class.expects(:rlist).returns YAML.load_file(my_fixture('role-list.yml'))
      described_class.prefetch({})
    end
  end
  
  describe "when asking exists?" do
    it "should return true if resource is present" do
      role.provider.set(:ensure => :present)
      role.provider.should be_exists
    end

    it "should return false if resource is absent" do
      role.provider.set(:ensure => :absent)
      role.provider.should_not be_exists
    end
  end
  
  describe "when creating a resource" do
    it "should be able to create a role" do    
      role.provider.expects(:radd).with('useradmin-role', is_a(NaElement))
      role.provider.create
    end
  end
  
  describe "when destroying a resource" do
    it "should be able to destroy a role" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      role.provider.set(:rolename => 'role')
      role.provider.expects(:rdel).with('role-name', 'role')
      role.provider.destroy
      role.provider.flush
    end
  end
  
  describe "when modifying a resource" do
    it "should be able to modify an existing role" do
      # Need to have a resource present that we can modify
      role.provider.set(:rolename => 'role', :ensure => :present, :capabilities => ['login-*'])
      role.provider.expects(:rmodify).with('useradmin-role', is_a(NaElement))
      role.provider.flush
    end
  end
  
end