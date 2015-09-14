#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_quota).provider(:sevenmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_quota).stubs(:defaultprovider).returns described_class
  end

  let :tree_quota do
    Puppet::Type.type(:netapp_quota).new(
      :name     => '/vol/vol1/qtree1',
      :ensure   => :present,
      :volume   => 'vol1',
      :type     => :tree,
      :provider => provider
    )
  end

  let :user_quota do
    Puppet::Type.type(:netapp_quota).new(
      :name     => 'bob',
      :ensure   => :present,
      :volume   => 'vol1',
      :qtree    => 'qtree1',
      :type     => :user,
      :provider => provider
    )
  end

  let :group_quota do
    Puppet::Type.type(:netapp_quota).new(
      :name     => 'staff',
      :ensure   => :present,
      :volume   => 'vol1',
      :qtree    => 'qtree1',
      :type     => :group,
      :provider => provider
    )
  end

  let :provider do
    described_class.new(
      :name => '/vol/vol1/qtree1'
    )
  end


  describe "#size_in_byte" do
    it "should convert a value with no unit to an integer" do
      described_class.size_in_byte("1024").should == 1024
    end

    it "should convert a value specified in KiB (unit=K)" do
      described_class.size_in_byte("100K").should == 102400
    end

    it "should convert a value specified in MiB (unit=M)" do
      described_class.size_in_byte("3M").should == 3145728
    end

    it "should convert a value specified in GiB (unit=G)" do
      described_class.size_in_byte("20G").should == 21474836480
    end

    it "should convert a value specified in TiB (unit=T)" do
      described_class.size_in_byte("4T").should == 4398046511104
    end

    it "should raise an error on negative values" do
      expect { described_class.size_in_byte("-20") }.to raise_error(ArgumentError, 'Invalid input "-20"')
    end

    it "should raise an error for unknown units" do
      expect { described_class.size_in_byte("3R") }.to raise_error(ArgumentError, 'Invalid input "3R"')
    end

    it "should raise an error on non numeric values" do
      expect { described_class.size_in_byte("G") }.to raise_error(ArgumentError, 'Invalid input "G"')
    end
  end

  describe "#instances" do
    it "should return an array of current quota entries" do
      described_class.expects(:list).with('include-output-entry', 'true').returns YAML.load_file(my_fixture('quota-list-entries.yml'))
      instances = described_class.instances
      instances.size.should == 3
      instances.map do |prov|
        {
          :name          => prov.get(:name),
          :ensure        => prov.get(:ensure),
          :qtree         => prov.get(:qtree),
          :type          => prov.get(:type),
          :disklimit     => prov.get(:disklimit),
          :softdisklimit => prov.get(:softdisklimit),
          :filelimit     => prov.get(:filelimit),
          :softfilelimit => prov.get(:softfilelimit),
          :threshold     => prov.get(:threshold),
          :volume        => prov.get(:volume)
        }
      end.should == [
        {
          :name          => '/vol/FILER01P_vol1/some-share',
          :ensure        => :present,
          :qtree         => :absent,
          :type          => :tree,
          :disklimit     => 5368709120, # 5G
          :softdisklimit => :absent,
          :filelimit     => :absent,
          :softfilelimit => :absent,
          :threshold     => :absent,
          :volume        => 'FILER01P_vol1'
        },
        {
          :name          => '/vol/vol3/some_other-share',
          :ensure        => :present,
          :qtree         => :absent,
          :type          => :tree,
          :disklimit     => 200 * 1024 * 1024, # 200M
          :softdisklimit => :absent,
          :filelimit     => :absent,
          :softfilelimit => :absent,
          :threshold     => :absent,
          :volume        => 'vol3'
        },
        {
          :name          => 'bob',
          :ensure        => :present,
          :qtree         => 'bob_h',
          :type          => :user,
          :disklimit     => 100*1024*1024, # 100M
          :softdisklimit => 90*1024*1024, # 90M
          :filelimit     => 10240, # 10K
          :softfilelimit => 9*1024, # 9K
          :threshold     => 90*1024*1024, # 90M
          :volume        => 'home'
        }
      ]
    end
  end

  describe "when asking exists?" do
    it "should return true if resource is present" do
      tree_quota.provider.set(:ensure => :present)
      tree_quota.provider.should be_exists
    end

    it "should return false if resource is absent" do
      tree_quota.provider.set(:ensure => :absent)
      tree_quota.provider.should_not be_exists
    end
  end

  describe "when creating a resource" do
    it "should be able to create a tree resource" do
      tree_quota.provider.expects(:add).with('quota-target', '/vol/vol1/qtree1', 'quota-type', 'tree', 'volume', 'vol1', 'qtree', '')
      tree_quota.provider.create
    end

    {
      :disklimit     => 'disk-limit',
      :softdisklimit => 'soft-disk-limit',
      :threshold     => 'threshold'
    }.each do |limit_property, api_property|
      describe "with a #{limit_property}" do
        {
          'absent' => '-',
          '300K'   => '300',
          '20M'    => '20480',
          '3G'     => '3145728',
          '1T'     => '1073741824'
        }.each do |limit_value, api_value|
          it "should pass #{api_value} if desired value is #{limit_value}" do
            tree_quota[limit_property] = limit_value
            tree_quota.provider.expects(:add).with('quota-target', '/vol/vol1/qtree1', 'quota-type', 'tree', 'volume', 'vol1', 'qtree', '', api_property, api_value)
            tree_quota.provider.create
          end
        end
      end
    end

    {
      :filelimit     => 'file-limit',
      :softfilelimit => 'soft-file-limit'
    }.each do |limit_property, api_property|
      describe "with a #{limit_property}" do
        {
          'absent' => '-',
          '300'    => '300',
          '2K'     => '2048',
          '30M'    => '31457280',
          '5G'     => '5368709120',
          '1T'     => '1099511627776'
        }.each do |limit_value, api_value|
          it "should pass #{api_value} if desired value is #{limit_value}" do
            tree_quota[limit_property] = limit_value
            tree_quota.provider.expects(:add).with('quota-target', '/vol/vol1/qtree1', 'quota-type', 'tree', 'volume', 'vol1', 'qtree', '', api_property, api_value)
            tree_quota.provider.create
          end
        end
      end
    end
  end

  describe "when destroying a resource" do
    it "should be able to destroy a tree quota" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      tree_quota.provider.set(:type => :tree, :volume => 'vol1')
      tree_quota.provider.expects(:del).with('quota-target', '/vol/vol1/qtree1', 'quota-type', 'tree', 'volume', 'vol1', 'qtree', '')
      tree_quota.provider.destroy
    end

    it "should be able to destroy a user quota" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      user_quota.provider.set(:name => 'bob', :type => :user, :volume => 'vol1', :qtree => 'q1')
      user_quota.provider.expects(:del).with('quota-target', 'bob', 'quota-type', 'user', 'volume', 'vol1', 'qtree', 'q1')
      user_quota.provider.destroy
    end

    it "should be able to destroy a group quota" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      group_quota.provider.set(:name => 'staff', :type => :group, :volume => 'vol1', :qtree => 'q1')
      group_quota.provider.expects(:del).with('quota-target', 'staff', 'quota-type', 'group', 'volume', 'vol1', 'qtree', 'q1')
      group_quota.provider.destroy
    end
  end

  describe "when querying the current value of a property" do
    {
      :type          => :tree,
      :volume        => 'vol1',
      :qtree         => 'qtree1',
      :disklimit     => 500,
      :softdisklimit => 300,
      :filelimit     => 100,
      :softfilelimit => 50,
      :threshold     => 20
    }.each do |property, sample_value|
      describe "for #{property}" do
        it "should get the cached value if possible" do
          provider.set(property => sample_value)
          provider.send(property).should == sample_value
        end

        it "should return absent otherwise" do
          provider.send(property).should == :absent
        end
      end
    end
  end

  describe "when modifying a property" do
    [:type, :volume, :qtree].each do |immutable_prop|
      describe immutable_prop do
        it "should not allow setting #{immutable_prop}" do
          expect { provider.send("#{immutable_prop}=", "some_value") }.to raise_error(Puppet::Error, /Please perform the necessary steps manually/)
        end
      end
    end

    {
      :disklimit     => 'disk-limit',
      :softdisklimit => 'soft-disk-limit',
      :threshold     => 'threshold'
    }.each do |property, apiproperty|
      describe property do
        it "should pass \"-\" as a value for #{apiproperty} if desired value is absent" do
          user_quota.provider.set(:name => 'bob', :type => :user, :qtree => 'qtree01', :volume => 'vol01')
          user_quota.provider.expects(:mod).with('quota-target', 'bob', 'quota-type', 'user', 'volume', 'vol01', 'qtree', 'qtree01', apiproperty, '-')
          user_quota.provider.send("#{property}=", :absent)
        end

        it "should convert value to KB if desired value is numeric" do
          user_quota.provider.set(:name => 'bob', :type => :user, :qtree => 'qtree01', :volume => 'vol01')
          user_quota.provider.expects(:mod).with('quota-target', 'bob', 'quota-type', 'user', 'volume', 'vol01', 'qtree', 'qtree01', apiproperty, '102400')
          user_quota.provider.send("#{property}=", 104857600) # 100MB
        end

        it "should pass \"\" as a qtree for tree quotas" do
          tree_quota.provider.set(:name => '/vol/vol1/qtree1', :type => :tree, :volume => 'vol3')
          tree_quota.provider.expects(:mod).with('quota-target', '/vol/vol1/qtree1', 'quota-type', 'tree', 'volume', 'vol3', 'qtree', '', apiproperty, '4')
          tree_quota.provider.send("#{property}=", 4096)
        end
      end
    end

    {
      :filelimit     => 'file-limit',
      :softfilelimit => 'soft-file-limit'
    }.each do |property, apiproperty|
      describe property do
        it "should pass \"-\" as a value for #{apiproperty} if desired value is absent" do
          user_quota.provider.set(:name => 'bob', :type => :user, :qtree => 'qtree01', :volume => 'vol01')
          user_quota.provider.expects(:mod).with('quota-target', 'bob', 'quota-type', 'user', 'volume', 'vol01', 'qtree', 'qtree01', apiproperty, '-')
          user_quota.provider.send("#{property}=", :absent)
        end

        it "should pass the desired value if desired value is numeric" do
          user_quota.provider.set(:name => 'bob', :type => :user, :qtree => 'qtree01', :volume => 'vol01')
          user_quota.provider.expects(:mod).with('quota-target', 'bob', 'quota-type', 'user', 'volume', 'vol01', 'qtree', 'qtree01', apiproperty, '104857600')
          user_quota.provider.send("#{property}=", 104857600) # 100M
        end

        it "should pass \"\" as a qtree for tree quotas" do
          tree_quota.provider.set(:name => '/vol/vol1/qtree1', :type => :tree, :volume => 'vol3')
          tree_quota.provider.expects(:mod).with('quota-target', '/vol/vol1/qtree1', 'quota-type', 'tree', 'volume', 'vol3', 'qtree', '', apiproperty, '4096')
          tree_quota.provider.send("#{property}=", 4096)
        end
      end
    end
  end

  describe "#flush" do

    let :quota_on do
      YAML.load_file(my_fixture('quota-status-result-on.yml'))
    end

    let :quota_off do
      YAML.load_file(my_fixture('quota-status-result-off.yml'))
    end

    describe "when a complete reload is not necessary" do
      it "should call resize if quota is activated for that volume" do
        provider.set(:volume => 'vol01')
        provider.expects(:status).with('volume', 'vol01').returns quota_on
        provider.expects(:resize).with('volume', 'vol01')
        provider.expects(:qoff).never
        provider.expects(:qon).never
        provider.flush
      end

      it "should do nothing if quota is deactivated for that volume" do
        provider.set(:volume => 'vol01')
        provider.expects(:status).with('volume', 'vol01').returns quota_off
        provider.expects(:resize).never
        provider.expects(:qoff).never
        provider.expects(:qon).never
        provider.flush
      end
    end

    describe "when a complete reload is necessary" do
      before :each do
        provider.instance_variable_set(:@need_restart, true)
      end

      it "should turn quota off and back on if quota is activated for that volume" do
        provider.set(:volume => 'vol01')
        provider.expects(:status).with('volume', 'vol01').returns quota_on
        provider.expects(:resize).never
        seq = sequence 'restart quota'
        provider.expects(:qoff).with('volume', 'vol01').in_sequence(seq)
        provider.expects(:qon).with('volume', 'vol01').in_sequence(seq)
        provider.flush
      end

      it "should do nothing if quota is deactivated for that volume" do
        provider.set(:volume => 'vol01')
        provider.expects(:status).with('volume', 'vol01').returns quota_off
        provider.expects(:resize).never
        provider.expects(:qoff).never
        provider.expects(:qon).never
        provider.flush
      end
    end
  end
end
