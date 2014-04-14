#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_qtree).provider(:netapp_qtree) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_qtree).stubs(:defaultprovider).returns described_class
  end
  
  let :volume_qtree do
    Puppet::Type.type(:netapp_qtree).new(
      :name     => 'qtree',
      :ensure   => :present,
      :volume   => 'volume',
      :provider => provider
    )    
  end
  
  let :provider do
    described_class.new(
      :name => 'qtree'
    )
  end
  
  describe "#instances" do
    it "should return an array of current qtree entries" do
      described_class.expects(:qlist).returns YAML.load_file(my_fixture('qtree-list.yml'))
      instances = described_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
          :name          => prov.get(:name),
          :ensure        => prov.get(:ensure),
          :volume        => prov.get(:volume)
        }
      end.should == [
        {
          :name          => 'qtree',
          :ensure        => :present,
          :volume        => 'volume'
        }
      ]
    end
  end
  
  describe "#prefetch" do
    it "exists" do
      described_class.expects(:qlist).returns YAML.load_file(my_fixture('qtree-list.yml'))
      described_class.prefetch({})
    end
  end
  
  describe "when asking exists?" do
    it "should return true if resource is present" do
      volume_qtree.provider.set(:ensure => :present)
      volume_qtree.provider.should be_exists
    end

    it "should return false if resource is absent" do
      volume_qtree.provider.set(:ensure => :absent)
      volume_qtree.provider.should_not be_exists
    end
  end
  
  describe "when creating a resource" do
    it "should be able to create a qtree" do
      volume_qtree.provider.expects(:qadd).with('qtree', 'qtree', 'volume', 'volume')
      volume_qtree.provider.create
    end
  end
  
  describe "when destroying a resource" do
    it "should be able to destroy a qtree" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      volume_qtree.provider.set(:name => 'qtree', :volume => 'volume')
      volume_qtree.provider.expects(:qdel).with('qtree', "/vol/volume/qtree")
      volume_qtree.provider.destroy
      volume_qtree.provider.flush
    end
  end
  
end