#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_volume).provider(:netapp_volume) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_volume).stubs(:defaultprovider).returns described_class
  end
  
  let :volume do
    Puppet::Type.type(:netapp_volume).new(
      :name          => 'volume',
      :ensure        => :present,
      :initsize      => '20m',
      :aggregate     => 'aggr1',
      :spaceres      => 'none',
      :snapreserve   => '0',
      :autoincrement => true,
      :options       => {'convert_ucode' => 'off', 'no_atime_update' => 'on', 'try_first' => 'volume_grow'},
      :snapschedule  => {'days' => 0, 'minutes' => 0, 'weeks' => 0, 'hours' => 24},
      :provider      => provider
    )    
  end
  
  let :provider do
    described_class.new(
      :name => 'volume'
    )
  end
  
  describe "#instances" do
    it "should return an array of current volume entries" do
      described_class.expects(:vollist).returns YAML.load_file(my_fixture('volume-list.yml'))
      described_class.expects(:optslist).at_least_once.returns YAML.load_file(my_fixture('volume-options-list.yml'))
      described_class.expects(:snapschedlist).at_least_once.returns YAML.load_file(my_fixture('volume-snapsched-list.yml'))        
      instances = described_class.instances
      instances.size.should == 3
      instances.map do |prov|
        {
          :name          => prov.get(:name),
          :ensure        => prov.get(:ensure),
          :state         => prov.get(:state),
          :initsize      => prov.get(:initsize),
          :snapreserve   => prov.get(:snapreserve),
          :autoincrement => prov.get(:autoincrement),
          :options       => prov.get(:options),
          :snapschedule  => prov.get(:snapschedule)
        }
      end.should == [
        {
          :name          => 'volume_online_1g',
          :ensure        => :present,
          :state         => 'online',
          :initsize      => '1g',
          :snapreserve   => 0,
          :autoincrement => :true,
          :options       => { "convert_ucode"=>"on",
                              "create_ucode"=>"off",
                              "svo_enable"=>"off",
                              "svo_allow_rman"=>"off",
                              "svo_checksum"=>"off",
                              "svo_reject_errors"=>"off",
                              "extent"=>"off",
                              "read_realloc"=>"off",
                              "fs_size_fixed"=>"off",
                              "ignore_inconsistent"=>"off",
                              "maxdirsize"=>"11704",
                              "max_write_alloc_blocks"=>"0",
                              "minra"=>"off",
                              "no_atime_update"=>"on",
                              "no_i2p"=>"off",
                              "no_delete_log"=>"off",
                              "dlog_hole_reserve"=>"off",
                              "nosnap"=>"off",
                              "nosnapdir"=>"off",
                              "schedsnapname"=>"ordinal",
                              "nvfail"=>"off",
                              "try_first"=>"volume_grow",
                              "fractional_reserve"=>"0",
                              "actual_guarantee"=>"none",
                              "snapshot_clone_dependency"=>"off",
                              "effective_guarantee"=>"none",
                              "raidsize"=>"10",
                              "raidtype"=>"raid_dp",
                              "resyncsnaptime"=>"60",
                              "root"=>"false",
                              "snapmirrored"=>"off",
                              "upgraded_replica"=>"false",
                              "raid_cv"=>"on",
                              "thorough_scrub"=>"off",
                              "nbu_archival_snap"=>"off",
                              "ha_policy"=>"cfo",
                              "striping"=>"not_striped",
                              "compression"=>"off"},
          :snapschedule  => { "minutes"=>"0",
                              "hours"=>"0",
                              "days"=>"0",
                              "weeks"=>"0",
                              "which-hours"=>" ",
                              "which-minutes"=>" "}
        },
        {
          :name          => 'volume_online_1t_noautoincr',
          :ensure        => :present,
          :state         => 'online',
          :initsize      => '1t',
          :snapreserve   => 0,
          :autoincrement => :false,
          :options       => { "convert_ucode"=>"on",
                              "create_ucode"=>"off",
                              "svo_enable"=>"off",
                              "svo_allow_rman"=>"off",
                              "svo_checksum"=>"off",
                              "svo_reject_errors"=>"off",
                              "extent"=>"off",
                              "read_realloc"=>"off",
                              "fs_size_fixed"=>"off",
                              "ignore_inconsistent"=>"off",
                              "maxdirsize"=>"11704",
                              "max_write_alloc_blocks"=>"0",
                              "minra"=>"off",
                              "no_atime_update"=>"on",
                              "no_i2p"=>"off",
                              "no_delete_log"=>"off",
                              "dlog_hole_reserve"=>"off",
                              "nosnap"=>"off",
                              "nosnapdir"=>"off",
                              "schedsnapname"=>"ordinal",
                              "nvfail"=>"off",
                              "try_first"=>"volume_grow",
                              "fractional_reserve"=>"0",
                              "actual_guarantee"=>"none",
                              "snapshot_clone_dependency"=>"off",
                              "effective_guarantee"=>"none",
                              "raidsize"=>"10",
                              "raidtype"=>"raid_dp",
                              "resyncsnaptime"=>"60",
                              "root"=>"false",
                              "snapmirrored"=>"off",
                              "upgraded_replica"=>"false",
                              "raid_cv"=>"on",
                              "thorough_scrub"=>"off",
                              "nbu_archival_snap"=>"off",
                              "ha_policy"=>"cfo",
                              "striping"=>"not_striped",
                              "compression"=>"off"},
          :snapschedule  => { "minutes"=>"0",
                              "hours"=>"0",
                              "days"=>"0",
                              "weeks"=>"0",
                              "which-hours"=>" ",
                              "which-minutes"=>" "}
        },
        {
          :name          => 'volume_offline_200g',
          :ensure        => :present,
          :state         => 'offline',
          :initsize      => '200g',
          :snapreserve   => 0,
          :autoincrement => :true,
          :options       => { "convert_ucode"=>"on",
                              "create_ucode"=>"off",
                              "svo_enable"=>"off",
                              "svo_allow_rman"=>"off",
                              "svo_checksum"=>"off",
                              "svo_reject_errors"=>"off",
                              "extent"=>"off",
                              "read_realloc"=>"off",
                              "fs_size_fixed"=>"off",
                              "ignore_inconsistent"=>"off",
                              "maxdirsize"=>"11704",
                              "max_write_alloc_blocks"=>"0",
                              "minra"=>"off",
                              "no_atime_update"=>"on",
                              "no_i2p"=>"off",
                              "no_delete_log"=>"off",
                              "dlog_hole_reserve"=>"off",
                              "nosnap"=>"off",
                              "nosnapdir"=>"off",
                              "schedsnapname"=>"ordinal",
                              "nvfail"=>"off",
                              "try_first"=>"volume_grow",
                              "fractional_reserve"=>"0",
                              "actual_guarantee"=>"none",
                              "snapshot_clone_dependency"=>"off",
                              "effective_guarantee"=>"none",
                              "raidsize"=>"10",
                              "raidtype"=>"raid_dp",
                              "resyncsnaptime"=>"60",
                              "root"=>"false",
                              "snapmirrored"=>"off",
                              "upgraded_replica"=>"false",
                              "raid_cv"=>"on",
                              "thorough_scrub"=>"off",
                              "nbu_archival_snap"=>"off",
                              "ha_policy"=>"cfo",
                              "striping"=>"not_striped",
                              "compression"=>"off"},
          :snapschedule  => :absent
        }
      ]
    end
  end
  
  describe "#prefetch" do
    it "exists" do
      described_class.expects(:vollist).returns YAML.load_file(my_fixture('volume-list.yml'))
      described_class.expects(:optslist).at_least_once.returns YAML.load_file(my_fixture('volume-options-list.yml'))
      described_class.expects(:snapschedlist).at_least_once.returns YAML.load_file(my_fixture('volume-snapsched-list.yml'))
      described_class.prefetch({})
    end
  end
  
  describe "when asking exists?" do
    it "should return true if resource is present" do
      volume.provider.set(:ensure => :present)
      volume.provider.should be_exists
    end

    it "should return false if resource is absent" do
      volume.provider.set(:ensure => :absent)
      volume.provider.should_not be_exists
    end
  end
  
  describe "when creating a resource" do
    it "should be able to create an online volume" do    
      volume.provider.expects(:volcreate).with('volume', 'volume', 'size', '20m', 'containing-aggr-name', 'aggr1', 'language-code', :en, 'space-reserve', :none)
      volume.provider.expects(:autosizeset).with('volume', 'volume', 'is-enabled', :true, 'maximum-size', '24m', 'increment-size', '1m')
      volume.provider.expects(:voloptset).with('volume', 'volume', 'option-name', 'convert_ucode', 'option-value', 'off')
      volume.provider.expects(:voloptset).with('volume', 'volume', 'option-name', 'no_atime_update', 'option-value', 'on')
      volume.provider.expects(:voloptset).with('volume', 'volume', 'option-name', 'try_first', 'option-value', 'volume_grow')
      volume.provider.expects(:snapresset).with('volume', 'volume', 'percentage', 0)
      volume.provider.expects(:snapschedset).with('volume', 'volume', 'weeks', '0', 'days', '0', 'hours', '24', 'minutes', '0', 'which-hours', '', 'which-minutes', '')
      volume.provider.create
    end
    
    it "should be able to create an offline volume" do
      volume[:state] = :offline
      volume.provider.expects(:volcreate).with('volume', 'volume', 'size', '20m', 'containing-aggr-name', 'aggr1', 'language-code', :en, 'space-reserve', :none)
      volume.provider.expects(:autosizeset).with('volume', 'volume', 'is-enabled', :true, 'maximum-size', '24m', 'increment-size', '1m')
      volume.provider.expects(:voloptset).at_least_once
      volume.provider.expects(:snapresset).with('volume', 'volume', 'percentage', 0)
      volume.provider.expects(:snapschedset).with('volume', 'volume', 'weeks', '0', 'days', '0', 'hours', '24', 'minutes', '0', 'which-hours', '', 'which-minutes', '')
      volume.provider.expects(:voloffline).with('name', 'volume')
      volume.provider.create
    end
    
    it "should be able to create a restricted volume" do
      volume[:state] = :restricted
      volume.provider.expects(:volcreate).with('volume', 'volume', 'size', '20m', 'containing-aggr-name', 'aggr1', 'language-code', :en, 'space-reserve', :none)
      volume.provider.expects(:autosizeset).with('volume', 'volume', 'is-enabled', :true, 'maximum-size', '24m', 'increment-size', '1m')
      volume.provider.expects(:voloptset).at_least_once
      volume.provider.expects(:snapresset).with('volume', 'volume', 'percentage', 0)
      volume.provider.expects(:snapschedset).with('volume', 'volume', 'weeks', '0', 'days', '0', 'hours', '24', 'minutes', '0', 'which-hours', '', 'which-minutes', '')
      volume.provider.expects(:volrestrict).with('name', 'volume')
      volume.provider.create
    end
  end
  
  describe "when destroying a resource" do
    it "should be able to destroy an online volume" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      volume.provider.set(:name => 'volume')
      volume.provider.expects(:vollist).with('volume', 'volume').returns YAML.load_file(my_fixture('volume-list-online.yml'))
      volume.provider.expects(:voloffline).with('name', 'volume')
      volume.provider.expects(:voldestroy).with('name', 'volume')
      volume.provider.destroy
      volume.provider.flush
    end
    
    it "should be able to destroy an offline volume" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      volume.provider.set(:name => 'volume')
      volume.provider.expects(:vollist).with('volume', 'volume').returns YAML.load_file(my_fixture('volume-list-offline.yml'))
      volume.provider.expects(:voldestroy).with('name', 'volume')
      volume.provider.destroy
      volume.provider.flush
    end
    
    it "should be able to destroy a restricted volume" do
      # if we destroy a provider, we must have been present before so we must have values in @property_hash
      volume.provider.set(:name => 'volume')
      volume.provider.expects(:vollist).with('volume', 'volume').returns YAML.load_file(my_fixture('volume-list-restricted.yml'))
      volume.provider.expects(:voldestroy).with('name', 'volume')
      volume.provider.destroy
      volume.provider.flush
    end
  end
  
  describe "when modifying a resource" do
    describe "for #initsize=" do
      it "should be able to resize an existing volume with autoincrement enabled" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :initsize => '1g')
        volume[:initsize] = '2g'
        volume.provider.expects(:volsizeset).with('volume', 'volume', 'new-size', '2g')
        volume.provider.expects(:autosizeset).with('volume', 'volume', 'is-enabled', :true, 'maximum-size', '2457m', 'increment-size', '102m')
        volume.provider.send("initsize=", '2g')
      end
      
      it "should be able to resize an existing volume with autoincrement disabled" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :initsize => '1g', :autoincrement => :false)
        volume[:initsize] = '2g'
        volume[:autoincrement] = :false
        volume.provider.expects(:volsizeset).with('volume', 'volume', 'new-size', '2g')
        volume.provider.send("initsize=", '2g')
      end
    end
    
    describe "for #snapreserve=" do
      it "should be able to modify snapreserve value on an existing volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :snapreserve => 0)
        volume[:snapreserve] = '10'
        volume.provider.expects(:snapresset).with('volume', 'volume', 'percentage', 10)
        volume.provider.send("snapreserve=", 10)
      end
    end
    
    describe "for #autoincrement=" do
      it "should be enable autoincrement on an existing volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :autoincrement => :false)
        volume[:autoincrement] = :true
        volume.provider.expects(:autosizeset).with('volume', 'volume', 'is-enabled', :true, 'maximum-size', '24m', 'increment-size', '1m')
        volume.provider.send("autoincrement=", :true)
      end
      
      it "should be disable autoincrement on an existing volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :autoincrement => :true)
        volume[:autoincrement] = :false
        volume.provider.expects(:autosizeset).with('volume', 'volume', 'is-enabled', :false)
        volume.provider.send("autoincrement=", :false)
      end
    end
    
    describe "for #state=" do
      it "should be able to offline an existing online volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :state => :online)
        volume[:state] = :offline
        volume.provider.expects(:voloffline).with('name', 'volume')
        volume.provider.send("state=", :offline)
      end
      
      it "should be able to restrict an existing online volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :state => :online)
        volume[:state] = :restricted
        volume.provider.expects(:volrestrict).with('name', 'volume')
        volume.provider.send("state=", :restricted)
      end
      
      it "should be able to offline an existing online volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :state => :online)
        volume[:state] = :offline
        volume.provider.expects(:voloffline).with('name', 'volume')
        volume.provider.send("state=", :offline)
      end
      
      it "should be able to online an existing offline volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :state => :offline)
        volume[:state] = :online
        volume.provider.expects(:volonline).with('name', 'volume')
        volume.provider.send("state=", :online)
      end
      
      it "should be able to online an existing restricted volume" do
        # Need to have a resource present that we can modify
        volume.provider.set(:name => 'volume', :ensure => :present, :state => :restricted)
        volume[:state] = :online
        volume.provider.expects(:volonline).with('name', 'volume')
        volume.provider.send("state=", :online)
      end
    end 
  end
end