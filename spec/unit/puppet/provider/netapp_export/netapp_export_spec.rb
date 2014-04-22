#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_export).provider(:netapp_export) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_export).stubs(:defaultprovider).returns described_class
  end
  
  let :export_volume do
    Puppet::Type.type(:netapp_export).new(
      :name     => '/vol/volume',
      :ensure   => :present,
      :provider => provider
    )    
  end
  
  let :export_volume_rw do
    Puppet::Type.type(:netapp_export).new(
      :name      => '/vol/volume',
      :ensure    => :present,
      :readwrite => ['server1','192.168.150.50','192.168.150.51'],
      :readonly => ['all_hosts'],
      :provider  => provider
    )    
  end
  
  let :export_volume_ro do
    Puppet::Type.type(:netapp_export).new(
      :name      => '/vol/volume',
      :ensure    => :present,
      :readwrite => ['server1','192.168.150.50','192.168.150.51'],
      :readonly  => ['server2','192.168.150.55'],
      :provider  => provider
    )    
  end
  
  let :export_qtree do
    Puppet::Type.type(:netapp_export).new(
      :name     => '/vol/volume/qtree',
      :ensure   => :present,
      :provider => provider
    )    
  end
  
  let :export_volume_path do
    Puppet::Type.type(:netapp_export).new(
      :name     => '/vol/volume',
      :ensure   => :present,
      :path     => '/vol/othervolume',
      :provider => provider
    )    
  end
  
  let :provider do
    described_class.new(
      :name => '/vol/volume/qtree'
    )
  end
  
  describe "#instances" do
    it "should return an array of current export entries" do
      described_class.expects(:elist).returns YAML.load_file(my_fixture('export-list.yml'))
      instances = described_class.instances
      instances.size.should == 4
      instances.map do |prov|
        {
          :name      => prov.get(:name),
          :ensure    => prov.get(:ensure),
          :path      => prov.get(:path),
          :readonly  => prov.get(:readonly),
          :readwrite => prov.get(:readwrite)
        }
      end.should == [
        {
          :name      => '/vol/volume',
          :ensure    => :present,
          :path      => :absent, 
          :readonly  => ['all_hosts'],
          :readwrite => ['server1','192.168.150.50','192.168.150.51']
        },
        {
          :name      => '/vol/volume/qtree',
          :ensure    => :present,
          :path      => :absent,
          :readonly  => ['all_hosts'],
          :readwrite => ['server1','192.168.150.50','192.168.150.51']
        },
        {
          :name      => '/vol/othervolume',
          :ensure    => :present,
          :path      => '/vol/volume',
          :readonly  => :absent,
          :readwrite => ['all_hosts']
        },
        {
          :name      => '/vol/volume/otherqtree',
          :ensure    => :present,
          :path      => '/vol/volume/qtree',
          :readonly  => :absent,
          :readwrite => ['all_hosts']
        }
      ]
    end
  end
  
  describe "#prefetch" do
    it "exists" do
      described_class.expects(:elist).returns YAML.load_file(my_fixture('export-list.yml'))
      described_class.prefetch({})
    end
  end
  
  describe "when asking exists?" do
    it "should return true if resource is present" do
      export_volume.provider.set(:ensure => :present)
      export_volume.provider.should be_exists
    end

    it "should return false if resource is absent" do
      export_volume.provider.set(:ensure => :absent)
      export_volume.provider.should_not be_exists
    end
  end
  
  describe "when creating a resource" do
    it "should be able to create a volume export" do    
      export_volume.provider.expects(:eadd).with('persistent', 'true', 'verbose', 'true', 'rules', is_a(NaElement)).returns YAML.load_file(my_fixture('export-volume-response.yml'))
      export_volume.provider.create
    end
    
    it "should be able to create a volume export with a readwrite list" do    
      export_volume_rw.provider.expects(:eadd).with('persistent', 'true', 'verbose', 'true', 'rules', is_a(NaElement)).returns YAML.load_file(my_fixture('export-volume-response.yml'))
      export_volume_rw.provider.create
    end
    
    it "should be able to create a volume export with a readonly list" do    
      export_volume_ro.provider.expects(:eadd).with('persistent', 'true', 'verbose', 'true', 'rules', is_a(NaElement)).returns YAML.load_file(my_fixture('export-volume-response.yml'))
      export_volume_ro.provider.create
    end
    
    it "should be able to create a qtree export" do    
      export_qtree.provider.expects(:eadd).with('persistent', 'true', 'verbose', 'true', 'rules', is_a(NaElement)).returns YAML.load_file(my_fixture('export-qtree-response.yml'))
      export_qtree.provider.create
    end
    
    it "should raise an exception if the export creation fails" do
      export_volume.provider.expects(:eadd).with('persistent', 'true', 'verbose', 'true', 'rules', is_a(NaElement)).returns YAML.load_file(my_fixture('export-failed-response.yml'))
      expect { export_volume.provider.create }.to raise_error(Puppet::Error, /export rule \/vol\/volume creation failed. Verify settings./)
    end
  end
  
  describe "when destroying a resource" do
    it "should be able to destroy a volume export" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      export_volume.provider.set(:name => '/vol/volume', :path => '/vol/volume')
      export_volume.provider.expects(:edel).with('persistent', 'true', 'pathnames', is_a(NaElement))
      export_volume.provider.destroy
      export_volume.provider.flush
    end
    
    it "should be able to destroy a qtree export" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      export_qtree.provider.set(:name => '/vol/volume/qtree', :path => '/vol/volume/qtree')
      export_qtree.provider.expects(:edel).with('persistent', 'true', 'pathnames', is_a(NaElement))
      export_qtree.provider.destroy
      export_qtree.provider.flush
    end
  end
  
  describe "when modifying a resource" do
    it "should be able to modify an existing export path" do
      # Need to have a resource present that we can modify
      export_volume_path.provider.set(:name => '/vol/volume', :ensure => :present, :path => :absent)
      export_volume_path.provider.expects(:emodify).with('persistent', 'true', 'rule', is_a(NaElement))
      export_volume_path.provider.flush
    end
    
    it "should be able to modify an existing export readonly list" do
      # Need to have a resource present that we can modify
      export_volume_path.provider.set(:name => '/vol/volume', :ensure => :present, :path => :absent, :readonly => ['all_hosts'])
      export_volume_path[:readonly] = ['server1','192.168.150.50','192.168.150.51']
      export_volume_path.provider.expects(:emodify).with('persistent', 'true', 'rule', is_a(NaElement))
      export_volume_path.provider.flush
    end
    
    it "should be able to modify an existing export readwrite list" do
      # Need to have a resource present that we can modify
      export_volume_path.provider.set(:name => '/vol/volume', :ensure => :present, :path => :absent, :readonly => :absent, :readwrite => ['all_hosts'])
      export_volume_path[:readwrite] = ['server1','192.168.150.50','192.168.150.51']
      export_volume_path[:readonly] = ['all_hosts']
      export_volume_path.provider.expects(:emodify).with('persistent', 'true', 'rule', is_a(NaElement))
      export_volume_path.provider.flush
    end
  end
  
end