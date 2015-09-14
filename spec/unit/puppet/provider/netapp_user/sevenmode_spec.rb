#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_user).provider(:sevenmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_user).stubs(:defaultprovider).returns described_class
  end
  
  let :user do
    Puppet::Type.type(:netapp_user).new(
      :username => 'user',
      :ensure   => :present,
      :password => 'password',
      #:fullname => 'Full Name',
      :comment  => 'test user',
      :groups   => 'group1,group2',
      :provider => provider
    )    
  end
  
  let :provider do
    described_class.new(
      :username => 'user'
    )
  end
  
  describe "#instances" do
    it "should return an array of current user entries" do
      described_class.expects(:ulist).returns YAML.load_file(my_fixture('user-list.yml'))
      instances = described_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
          :username => prov.get(:username),
          :ensure   => prov.get(:ensure),
          #:password => prov.get(:password),
          #:fullname => prov.get(:fullname),
          :comment  => prov.get(:comment),
          :groups   => prov.get(:groups)
        }
      end.should == [
        {
          :username => 'user',
          :ensure   => :present,
          #:password => 'password',
          #:fullname => 'Full Name',
          :comment  => 'test user',
          :groups   => 'group1,group2',
        }
      ]
    end
  end
  
  describe "#prefetch" do
    it "exists" do
      described_class.expects(:ulist).returns YAML.load_file(my_fixture('user-list.yml'))
      described_class.prefetch({})
    end
  end
  
  describe "when asking exists?" do
    it "should return true if resource is present" do
      user.provider.set(:ensure => :present)
      user.provider.should be_exists
    end

    it "should return false if resource is absent" do
      user.provider.set(:ensure => :absent)
      user.provider.should_not be_exists
    end
  end
  
  describe "when creating a resource" do
    it "should be able to create a user" do    
      user.provider.expects(:uadd).with('useradmin-user', is_a(NaElement), 'password', 'password')
      user.provider.create
    end
  end
  
  describe "when destroying a resource" do
    it "should be able to destroy a group" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      user.provider.set(:username => 'user')
      user.provider.expects(:udel).with('user-name', 'user')
      user.provider.destroy
      user.provider.flush
    end
  end
  
  describe "when modifying a resource" do
    it "should be able to modify an existing group" do
      # Need to have a resource present that we can modify
      user.provider.set(:username => 'user', :ensure => :present, :groups => ['group1'])
      user.provider.expects(:umodify).with('useradmin-user', is_a(NaElement))
      user.provider.flush
    end
  end
  
end