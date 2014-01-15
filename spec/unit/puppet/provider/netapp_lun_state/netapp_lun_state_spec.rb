#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_lun_state).provider(:netapp_lun_state) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_lun_state).stubs(:defaultprovider).returns described_class
  end

  let :lun_online do
    Puppet::Type.type(:netapp_lun_state).new(
    :name                    => '/vol/testVolumeFCoE/testLun_test',
    :ensure                  => :present
    )
  end

  let :lun_offline do
    Puppet::Type.type(:netapp_lun_state).new(
    :name     => '/vol/testVolumeFCoE/testLun_test',
    :ensure   => :absent
    )
  end

  let :provider do
    described_class.new()
  end

  context "when netapp lun online provider is created " do
    it "should have create method defined for netapp lun online" do
      lun_online.provider.class.instance_method(:create).should_not == nil
    end

    it "should have destroy method defined for netapp lun online" do
      lun_online.provider.class.instance_method(:destroy).should_not == nil
    end

    it "should have exists? method defined for netapp lun online" do
      lun_online.provider.class.instance_method(:exists?).should_not == nil
    end

  end

  context "lun online" do
    it "should be able to online a lun resource" do
      #Then
      lun_online.provider.expects(:lunonline).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test')
      lun_online.provider.expects(:get_lun_status).at_most(3).with().returns('offline','online')
      lun_online.provider.expects(:err).never

      #When
      lun_online.provider.create
    end

    it "should not be able to map a lun resource" do
      #Then
      lun_online.provider.expects(:lunonline).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test')
      lun_online.provider.expects(:get_lun_status).at_most(2).with().returns('offline','offline')
      lun_online.provider.expects(:info).never

      #When
      expect {lun_online.provider.create}.to raise_error(Puppet::Error)
    end

    context "when removing mapping of a lun resource" do
      it "should be able to un-map a lun resource" do
        #Then
        lun_offline.provider.expects(:lunoffline).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test')
        lun_offline.provider.expects(:get_lun_status).at_most(2).with().returns('online','offline')
        lun_offline.provider.expects(:err).never

        #When
        lun_offline.provider.destroy
      end

      it "should not be able to un-map a lun resource" do
        #Then
        lun_offline.provider.expects(:lunoffline).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test')
        lun_offline.provider.expects(:get_lun_status).at_most(2).with().returns('online','online')
        lun_offline.provider.expects(:info).never

        #When
        expect {lun_offline.provider.destroy}.to raise_error(Puppet::Error)
      end

    end
  end
end